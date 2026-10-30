import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app import create_app
from local_sessions import LocalSessionStore
from reward_ledger import RewardLedger

class LocalSessionTests(unittest.TestCase):
    def test_sessions_persist_and_isolate_balance(self):
        with tempfile.TemporaryDirectory() as folder:
            database = Path(folder) / "rewards.sqlite3"
            ledger = RewardLedger(database)
            sessions = LocalSessionStore(database)
            app = create_app(ledger, local_sessions=sessions)

            def request(method, path, token=None):
                statuses = []
                environ = {"REQUEST_METHOD": method, "PATH_INFO": path}
                if token is not None:
                    environ["HTTP_AUTHORIZATION"] = "Bearer " + token
                data = b"".join(app(environ, lambda status, headers: statuses.append(status)))
                return statuses[0], json.loads(data)

            self.assertEqual(request("GET", "/v1/rewards/points")[0], "401 Unauthorized")
            status, first = request("POST", "/v1/rewards/local-session")
            self.assertEqual(status, "201 Created")
            self.assertNotEqual(first["accessToken"], first["userId"])
            second = request("POST", "/v1/rewards/local-session")[1]
            self.assertNotEqual(first["accessToken"], second["accessToken"])
            self.assertNotEqual(first["userId"], second["userId"])

            ledger.credit_verified(
                provider="tnk", transaction_id="confirmed-one",
                user_id=first["userId"], points=8
            )
            self.assertEqual(request("GET", "/v1/rewards/points", first["accessToken"])[1]["balance"], 8)
            self.assertEqual(request("GET", "/v1/rewards/points", second["accessToken"])[1]["balance"], 0)
            self.assertEqual(
                LocalSessionStore(database).verify(first["accessToken"]),
                first["userId"]
            )
            self.assertIsNone(sessions.verify("invalid"))

    def test_local_session_issuance_disabled_by_default(self):
        with tempfile.TemporaryDirectory() as folder:
            ledger = RewardLedger(Path(folder) / "rewards.sqlite3")
            app = create_app(ledger)
            statuses = []
            payload = b"".join(app(
                {"REQUEST_METHOD": "POST", "PATH_INFO": "/v1/rewards/local-session"},
                lambda status, headers: statuses.append(status)
            ))
            self.assertEqual(statuses[0], "404 Not Found")
            self.assertEqual(json.loads(payload)["error"], "not_found")

if __name__ == "__main__":
    unittest.main()
