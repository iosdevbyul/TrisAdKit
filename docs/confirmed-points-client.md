# Authenticated rewards integration

`RemoteRewardPointsProvider` consumes the read-only
`GET /v1/rewards/points` endpoint implemented under `server/`.

The host app injects its **own production-authenticated HTTPS origin and
per-user bearer token**. No host address, user identity or credentials
are bundled with TrisAdKit.

```swift
let provider = RemoteRewardPointsProvider(
    baseURL: URL(string: "https://your-authorized-reward-server.example")!,
    authorization: {
        // Obtain the signed-in user's current access token from the host.
        try await session.currentAccessToken()
    }
)
TrisSideHustleView(pointsProvider: provider)
```

Replace the placeholder URL and `session` with real host-app dependencies.
The package rejects HTTP and empty tokens, maps the ledger's ISO 8601
`awardedAt` entries into `Date`, and does not mint any points locally.

**Current deployment limitation:** PR #12's server uses local-only,
development bearer tokens and is not a production user identity service.
Do not point distributed iOS apps at it until a proper session validation
layer, HTTPS deployment and authenticated real-user mapping are implemented.
Coufunch currently keeps the fail-closed unconfigured provider until then.

Ad view callbacks are not proof of reward eligibility; only authenticated
server-side verified ledger awards appear in the balance.
