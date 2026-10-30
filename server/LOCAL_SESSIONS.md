# Local development reward sessions

This is a **development-only** way to test an independently generated, persistent user identity without hardcoding bearer tokens in Coufunch.

Start from the TrisAdKit repository root:

```sh
REWARD_ENABLE_LOCAL_SESSIONS=1 python3 server/app.py
```

The service binds `127.0.0.1:8765` by default. With local sessions explicitly enabled:

- `POST /v1/rewards/local-session` returns `{"accessToken":"...","userId":"local-..."}`.
- `GET /v1/rewards/points` requires `Authorization: Bearer <accessToken>`.
- Generated tokens are stored only as SHA-256 digests in the local SQLite database. Tokens survive process restarts; each issued token identifies a separate test user.
- Without `REWARD_ENABLE_LOCAL_SESSIONS=1`, the issuance endpoint returns HTTP 404.
- This mode is mutually exclusive with `REWARD_API_TOKENS_JSON`.

To use the existing TrisServerManager preset, select the TrisAdKit working directory and set the local command to `REWARD_ENABLE_LOCAL_SESSIONS=1 python3 server/app.py`. The manager's existing `/healthz` check still applies. Docker is **not required**.

**Not for production**: This is anonymous bearer-token issuance with no App Attest, device integrity, abuse limits, token revocation or real account recovery. Do not enable the issuance endpoint on any publicly reachable host, reverse proxy or production service. For real users and real rewards, integrate verified user authentication and a production TLS deployment. No TNK callback validation or actual ad-driven points issuance is implemented.
