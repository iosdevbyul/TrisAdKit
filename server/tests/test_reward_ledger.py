import io
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app import create_app
from reward_ledger import RewardLedger


class RewardLedgerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.ledger = RewardLedger(Path(self.tmp.name) / "ledger.sqlite3")

    def tearDown(self):
        self.tmp.cleanup()

    def test_verified_credit_and_duplicate_is_idempotent(self):
        self.assertEqual(self.ledger.credit_verified(
            provider="tnk", transaction_id="t1", user_id="u1", points=10), (True, 10))
        self.assertEqual(self.ledger.credit_verified(
            provider="tnk", transaction_id="t1", user_id="u1", points=10), (False, 10))
        self.assertEqual(self.ledger.snapshot("u1")["balance"], 10)

    def test_duplicate_cannot_credit_other_user_or_change_amount(self):
        self.ledger.credit_verified(provider="tnk", transaction_id="t1", user_id="u1", points=10)
        with self.assertRaises(ValueError):
            self.ledger.credit_verified(provider="tnk", transaction_id="t1", user_id="u2", points=10)
        with self.assertRaises(ValueError):
            self.ledger.credit_verified(provider="tnk", transaction_id="t1", user_id="u1", points=100)
        self.assertEqual(self.ledger.snapshot("u2")["balance"], 0)

    def test_isolation_and_balance_are_persistent(self):
        self.ledger.credit_verified(provider="tnk", transaction_id="t1", user_id="u1", points=10)
        self.ledger.credit_verified(provider="tnk", transaction_id="t2", user_id="u2", points=7)
        reopened = RewardLedger(Path(self.tmp.name) / "ledger.sqlite3")
        self.assertEqual(reopened.snapshot("u1")["balance"], 10)
        self.assertEqual(reopened.snapshot("u2")["balance"], 7)
        self.assertIsNone(reopened.status("u2", "t1"))

    def test_api_requires_auth_and_isolates_users(self):
        self.ledger.credit_verified(provider="tnk", transaction_id="t1", user_id="u1", points=10)
        app = create_app(self.ledger, {"a" * 32: "u1", "b" * 32: "u2"})

        def call(path, token=None):
            result = {}
            def start(status, headers):
                result["status"] = status
            environ = {"REQUEST_METHOD": "GET", "PATH_INFO": path}
            if token:
                environ["HTTP_AUTHORIZATION"] = "Bearer " + token
            body = b"".join(app(environ, start))
            return result["status"], json.loads(body)

        self.assertEqual(call("/v1/rewards/points")[0], "401 Unauthorized")
        status, data = call("/v1/rewards/points", "a" * 32)
        self.assertEqual(status, "200 OK")
        self.assertEqual(data["balance"], 10)
        self.assertEqual(call("/v1/rewards/transactions/t1", "b" * 32)[0], "404 Not Found")
        self.assertEqual(call("/v1/rewards/transactions/t1", "a" * 32)[1]["state"], "credited")


if __name__ == "__main__":
    unittest.main()
