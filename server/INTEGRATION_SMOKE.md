# Reward ledger integration smoke test

Run the offline server-to-client API contract test from the TrisAdKit repository root:

```sh
python3 -m unittest discover -s server/tests -v
```

The integration test exercises: local development session issuance, authenticated zero-point read, a **server-side test fixture** inserting one verified reward, idempotent replay, point balance and transaction API reads, data persistence after reopening SQLite, cross-user isolation, unauthorized access, and the default-disabled session route.

For a real same-Mac simulator smoke test:

1. Update TrisAdKit locally and run its Reward Ledger Server from TrisServerManager using `REWARD_ENABLE_LOCAL_SESSIONS=1 python3 server/app.py`.
2. Confirm `curl -fsS http://127.0.0.1:8765/healthz`.
3. Build Coufunch from merged PR #104 in Debug on iOS Simulator, open **부업**, and tap **새로고침**. Expect a server-backed **0 P** for a newly issued development identity.
4. Stop the server; refresh again. A request should fail and **must not generate points**.
5. Re-start the server; refresh and confirm connectivity again.

This does **not** verify a live TNK ad view or real award. The app currently holds the temporary bearer token in memory, so reinstall/new view lifecycle can create a different development identity. Real device / Release builds remain unconfigured. Only a Mac with the actual simulator and server can validate that final app-to-localhost network path.
