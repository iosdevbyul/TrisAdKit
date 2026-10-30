"""Transactional reward ledger. Standard-library SQLite; no TNK network calls."""
from __future__ import annotations

import sqlite3
from datetime import datetime, timezone
from pathlib import Path


class RewardLedger:
    def __init__(self, database: str | Path):
        self.database = str(database)
        self._initialize()

    def _connect(self):
        conn = sqlite3.connect(self.database, timeout=10, isolation_level=None)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA busy_timeout=10000")
        return conn

    def _initialize(self):
        with self._connect() as db:
            db.executescript("""
                PRAGMA journal_mode=WAL;
                CREATE TABLE IF NOT EXISTS reward_transactions (
                    provider TEXT NOT NULL,
                    transaction_id TEXT NOT NULL,
                    user_id TEXT NOT NULL,
                    points INTEGER NOT NULL CHECK(points > 0),
                    awarded_at TEXT NOT NULL,
                    PRIMARY KEY (provider, transaction_id)
                );
                CREATE INDEX IF NOT EXISTS reward_transactions_user_idx
                ON reward_transactions (user_id, awarded_at DESC);
            """)

    def credit_verified(self, *, provider: str, transaction_id: str,
                        user_id: str, points: int) -> tuple[bool, int]:
        """Caller MUST authenticate and verify ad-provider callback before calling.

        Returns (inserted, current_balance). Duplicate provider transactions are
        idempotent; a cross-user replay cannot move a credit to another account.
        """
        if not all((provider, transaction_id, user_id)) or points <= 0:
            raise ValueError("Invalid reward transaction")
        with self._connect() as db:
            db.execute("BEGIN IMMEDIATE")
            try:
                cursor = db.execute(
                    """INSERT OR IGNORE INTO reward_transactions
                    (provider, transaction_id, user_id, points, awarded_at)
                    VALUES (?, ?, ?, ?, ?)""",
                    (provider, transaction_id, user_id, points,
                     datetime.now(timezone.utc).isoformat()),
                )
                inserted = cursor.rowcount == 1
                if not inserted:
                    existing = db.execute(
                        """SELECT user_id, points FROM reward_transactions
                        WHERE provider=? AND transaction_id=?""",
                        (provider, transaction_id),
                    ).fetchone()
                    if existing["user_id"] != user_id or existing["points"] != points:
                        raise ValueError("Conflicting duplicate transaction")
                balance = db.execute(
                    """SELECT COALESCE(SUM(points), 0) FROM reward_transactions
                    WHERE user_id=?""",
                    (user_id,),
                ).fetchone()[0]
                db.execute("COMMIT")
                return inserted, balance
            except BaseException:
                db.execute("ROLLBACK")
                raise

    def snapshot(self, user_id: str, limit: int = 50) -> dict:
        if not user_id or not 1 <= limit <= 100:
            raise ValueError("Invalid ledger query")
        with self._connect() as db:
            balance = db.execute(
                "SELECT COALESCE(SUM(points), 0) FROM reward_transactions WHERE user_id=?",
                (user_id,),
            ).fetchone()[0]
            entries = db.execute(
                """SELECT provider, transaction_id, points, awarded_at
                FROM reward_transactions WHERE user_id=?
                ORDER BY awarded_at DESC, transaction_id DESC LIMIT ?""",
                (user_id, limit),
            ).fetchall()
        return {
            "balance": balance,
            "entries": [
                {"id": r["provider"] + ":" + r["transaction_id"],
                 "points": r["points"], "awardedAt": r["awarded_at"],
                 "description": "Verified rewarded video"}
                for r in entries
            ],
        }

    def status(self, user_id: str, transaction_id: str) -> dict | None:
        with self._connect() as db:
            r = db.execute(
                """SELECT points FROM reward_transactions
                WHERE user_id=? AND transaction_id=?""",
                (user_id, transaction_id),
            ).fetchone()
        if r is None:
            return None
        return {
            "transactionId": transaction_id, "state": "credited",
            "confirmedPoints": r["points"],
            "balance": self.snapshot(user_id)["balance"],
        }
