"""Development-only server-issued reward sessions, disabled unless explicitly enabled."""
import hashlib
import secrets
import sqlite3
from datetime import datetime, timezone

class LocalSessionStore:
    def __init__(self, database):
        self.database = str(database)
        with sqlite3.connect(self.database) as db:
            db.execute("""CREATE TABLE IF NOT EXISTS local_reward_sessions (
                token_digest TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                created_at TEXT NOT NULL
            )""")

    def issue(self):
        token = secrets.token_urlsafe(48)
        user_id = "local-" + secrets.token_hex(16)
        digest = hashlib.sha256(token.encode()).hexdigest()
        with sqlite3.connect(self.database) as db:
            db.execute(
                "INSERT INTO local_reward_sessions VALUES (?, ?, ?)",
                (digest, user_id, datetime.now(timezone.utc).isoformat()),
            )
        return {"accessToken": token, "userId": user_id}

    def verify(self, token):
        if not isinstance(token, str) or not token:
            return None
        digest = hashlib.sha256(token.encode()).hexdigest()
        with sqlite3.connect(self.database) as db:
            row = db.execute(
                "SELECT user_id FROM local_reward_sessions WHERE token_digest=?",
                (digest,),
            ).fetchone()
        return row[0] if row else None
