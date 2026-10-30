"""Offline end-to-end contract test: session -> ledger -> authenticated HTTP read."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app import create_app
from local_sessions import LocalSessionStore
from reward_ledger import RewardLedger


def request(app, method, path, token=None):
    result = {}
    environ = {"REQUEST_METHOD": method, "PATH_INFO": path}
    if token:
        environ["HTTP_AUTHORIZATION"] = "Bearer " + token

    def start(status, headers):
        result["status"] = status
        result["headers"] = dict(headers)

    payload = b"".join(app(environ, start))
    return result["status"], json.loads(payload)


class RewardEndToEndTests(unittest.TestCase):
    def test_session_credit_and_balance_survive_restart(self):
        with tempfile.TemporaryDirectory() as folder:
            db = Path(folder) / "ledger.sqlite3"
            ledger = RewardLedger(db)
            sessions = LocalSessionStore(db)
            app = create_app(ledger, local_sessions=sessions)

            status, created = request(app, "POST", "/v1/rewards/local-session")
            self.assertEqual(status, "201 Created")
            token, user_id = created["accessToken"], created["userId"]
            self.assertEqual(request(app, "GET", "/v1/rewards/points")[0], "401 Unauthorized")
            self.assertEqual(request(app, "GET", "/v1/rewards/points", token)[1]["balance"], 0)

            # Server-only test fixture. This is NOT an ad callback or client credit endpoint.
            credited, balance = ledger.credit_verified(
                provider="fixture", transaction_id="ad-1", user_id=user_id, points=7
            )
            self.assertTrue(credited)
            self.assertEqual(balance, 7)
            replay, balance = ledger.credit_verified(
                provider="fixture", transaction_id="ad-1", user_id=user_id, points=7
            )
            self.assertFalse(replay)
            self.assertEqual(balance, 7)

            restarted = create_app(RewardLedger(db), local_sessions=LocalSessionStore(db))
            status, snapshot = request(restarted, "GET", "/v1/rewards/points", token)
            self.assertEqual(status, "200 OK")
            self.assertEqual(snapshot["balance"], 7)
            self.assertEqual(len(snapshot["entries"]), 1)
            self.assertEqual(snapshot["entries"][0]["points"], 7)
            self.assertEqual(
                request(restarted, "GET", "/v1/rewards/transactions/ad-1", token)[1]["state"],
                "credited",
            )

            other_token = request(restarted, "POST", "/v1/rewards/local-session")[1]["accessToken"]
            self.assertEqual(request(restarted, "GET", "/v1/rewards/points", other_token)[1]["balance"], 0)
            self.assertEqual(
                request(restarted, "GET", "/v1/rewards/transactions/ad-1", other_token)[0],
                "404 Not Found",
            )
            self.assertEqual(request(restarted, "GET", "/v1/rewards/points", "invalid")[0], "401 Unauthorized")

    def test_local_session_route_stays_off_by_default(self):
        with tempfile.TemporaryDirectory() as folder:
            app = create_app(RewardLedger(Path(folder) / "ledger.sqlite3"))
            self.assertEqual(
                request(app, "POST", "/v1/rewards/local-session")[0],
                "404 Not Found",
            )


if __name__ == "__main__":
    unittest.main()
