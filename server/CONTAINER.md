# Local reward-ledger container

The container is a **development-only** points-ledger server, not a deployed rewards service. It runs the existing SQLite ledger and read-only endpoints with persistent data in a named Docker volume.

1. Generate a cryptographically random bearer token of at least 32 characters. Set `REWARD_API_TOKENS_JSON` as a JSON object mapping the token to a local development user ID. Never commit the token or distribute it inside an iOS app.
2. Run `docker compose -f server/compose.yaml up --build -d` from the repository root.
3. Check `curl -fsS http://127.0.0.1:8765/healthz`.
4. Use an authorized test token to read `GET /v1/rewards/points`; other requests receive HTTP 401.
5. Stop with `docker compose -f server/compose.yaml down`. This preserves the named database volume. Do not use `down -v` unless intentionally deleting local ledger data.

Docker Compose binds the exposed port only to 127.0.0.1 of the host. The application process binds inside the container to 0.0.0.0. The health endpoint reports process availability only; it does not prove database, identity provider or TNK readiness.

The token map is a local test adapter and does **not** provide production login. Before opening this service to the internet, implement verified per-user sessions, TLS reverse proxy, secret rotation, backup/restore, observability, provider-signed TNK callbacks and a production database migration path. Never award points from an unverified client event.

Run automated tests: `python3 -m unittest discover -s server/tests -v`.
