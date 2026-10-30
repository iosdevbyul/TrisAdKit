# Reward ledger server (local development)

This independent Python 3.12+ standard-library WSGI service keeps real
SQLite ledger records. It has no external Python dependencies or live TNK calls.

Run tests:

```sh
python3 -m unittest discover -s server/tests -v
```

Launch locally with a deliberately generated 32+ character token:

```sh
export REWARD_API_TOKENS_JSON='{"replace-with-random-token-at-least-32-chars":"local-test-user"}'
export REWARD_DATABASE='./rewards.sqlite3'
python3 server/app.py
```

Endpoints:
- `GET /v1/rewards/points` — authenticated balance and latest entries
- `GET /v1/rewards/transactions/{transactionId}` — authenticated confirmed status
- Header: `Authorization: Bearer <local-test-token>`

There is **no public endpoint for adding points**. Calls to
`RewardLedger.credit_verified` are an internal entry point exclusively for a
future server-verified TNK callback. Do not wire arbitrary client requests or
unverified video completion callbacks into that method.

The caller must first verify TNK's official signature format, bind the
verified user identity, apply server-side eligibility rules, and derive the
reward amount from trusted configuration. Provider callback SDK/secret has
not been supplied; this integration is intentionally NOT active.

The local mapping of tokens to users is a development-only stand-in for app
authentication. It is not a production token issuer or authorization system.
This WSGI process binds loopback; use real session verification, HTTPS,
network isolation, operational backups, observability and secret management
before production deployment. For concurrent multi-instance deployment,
evaluate a managed transactional database instead of sharing SQLite files.

The server is not publicly deployed, and Coufunch is not yet connected.
No monetary redemption, cash payouts or gift coupons are implemented.
