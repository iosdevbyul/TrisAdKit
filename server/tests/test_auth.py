import unittest
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from auth import reject_all_tokens, development_token_verifier

class AuthTests(unittest.TestCase):
    def test_default_denies(self):
        self.assertIsNone(reject_all_tokens('x'))

    def test_dev_token_map(self):
        verify = development_token_verifier({'a' * 32: 'user1'})
        self.assertEqual(verify('a' * 32), 'user1')
        self.assertIsNone(verify('wrong'))
