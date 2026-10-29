# Remote rewarded ad policy contract

The host app injects `RewardedAdPolicyProviding` into `RewardedAdPolicyController`. The shared package never assumes an endpoint or a publisher ID.

Example GET response (HTTP 200, JSON):

```json
{"isEnabled":false,"dailyViewLimit":0,"minimumSecondsBetweenViews":0,"displayPointsPerView":0}
```

- `isEnabled`: operator-controlled feature flag.
- `dailyViewLimit`: maximum rewarded video impressions per user per day, enforced on the trusted backend.
- `minimumSecondsBetweenViews`: cooldown, enforced on the backend.
- `displayPointsPerView`: informational points preview only. **Never credit points directly from this value.**

No remote endpoint is currently deployed. Until then, use `UnconfiguredRewardedAdPolicyProvider` and disabled policy. Remote loads require HTTPS. Network or decoding errors disable the feature. No production TNK SDK or keys are embedded.

A backend must independently validate a provider-signed reward callback, deduplicate the transaction ID, enforce frequency caps and compute confirmed points. Rewarded ad display and point redemption are not unlocked by this configuration API alone.
