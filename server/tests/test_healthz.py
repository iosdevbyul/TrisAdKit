import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app import create_app
from reward_ledger import RewardLedger

class HealthTests(unittest.TestCase):
    def test_health_without_session_and_points_restricted(self):
        with tempfile.TemporaryDirectory() as folder:
            app = create_app(RewardLedger(Path(folder) / "test.sqlite3"))
            def call(path):
                status = []
                body = b"".join(app({"REQUEST_METHOD": "GET", "PATH_INFO": path}, lambda value, headers: status.append(value)))
                return status[0], json.loads(body)
            self.assertEqual(call("/healthz"), ("200 OK", {"status": "ok"}))
            self.assertEqual(call("/v1/rewards/points")[0], "401 Unauthorized")

if __name__ == "__main__":
    unittest.main()
