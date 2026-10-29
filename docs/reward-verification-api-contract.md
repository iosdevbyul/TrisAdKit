# Reward verification API contract — proposed, not deployed

Scope: rewarded video points only. Cash payouts, coupons and offerwalls are not part of this contract.

## Trust boundary

1. iOS app starts authorized rewarded video using the selected provider implementation.
2. An ad-completed client callback is **not** authority to credit points.
3. Provider sends a signed server-to-server callback to the backend (setup requires a provider-issued signing credential and callback URL). Backend validates the provider's exact signature scheme, authenticates the callback and checks transaction identity.
4. Backend must insert the unique provider + transaction ID exactly once within the same atomic database transaction that credits the authenticated user ledger. Duplicate callback retries must return an idempotent result without crediting again.
5. Backend applies server-owned configuration, daily caps, cooldown and the points schedule. The client display points setting is advisory only.
6. iOS fetches confirmed balance via an authenticated points API, and optional transaction status via the protocol below. Never trust a client-sent award quantity.

## Proposed app API

- `GET /v1/rewards/transactions/{transactionId}`
- Authentication: `Authorization: Bearer <app user token>`
- Status: `200` with JSON `{"transactionId":"tx-123","state":"pending","confirmedPoints":null,"balance":null}`
- Once credited: `{"transactionId":"tx-123","state":"credited","confirmedPoints":5,"balance":105}`
- Rejected: `{"transactionId":"tx-123","state":"rejected","confirmedPoints":null,"balance":null}`
- Requests for nonexistent or other-user transactions must not reveal another user's rewards. Return an appropriate 404/authorization failure.
- `RewardPointsProviding` remains the authenticated, authoritative balance/history fetch abstraction; actual backend endpoint/format must be agreed before integration.

## Backend requirements (not implemented in this package)

- Dedicated callback route for the selected provider, distinct from the user-facing API.
- Credential rotation, provider-specific signature validation, replay prevention, retry handling and audit logging.
- Uniqueness constraint on `(provider, transaction_id)`.
- Atomic creation of ledger record and balance change, with user/account binding.
- Read-side authorization and no secret in source, Info.plist or client requests.
- All callback and integration tests must run without making live TNK requests.
- Always compare contractual support for point redemption before enabling any monetary rewards.

This PR adds only the **client status DI boundary and documented backend contract**. No TNK SDK, deployed API, user token provider, database, or live point issuance is included.
