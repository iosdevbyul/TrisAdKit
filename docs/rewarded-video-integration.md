# TNK REVUP rewarded video

The first provider is TNK REVUP, not TNK Offerwall.

`RewardedVideoProviding` supports dependency injection. The app passes a provider to `RewardedVideoCoordinator` and opens `TrisSideHustleView` with a callback to `coordinator.present()`. Ad SDK vendors can be swapped without modifying the feature screen.

`TNKRewardedVideoProvider` currently provides the **integration boundary**, not a concrete binary integration. Publisher approval, the current REVUP iOS SDK, required identifiers, callback mapping, and test-device setup are necessary before real rewarded ads can run.

Official product references:
- https://www.adiscope.com/
- https://www.tnkfactory.com/tnk/ko/tnk.home.main?action=developer

**Security:** `RewardedVideoResult.completed` signals an ad-completion callback only. Never award cash-convertible points on the device. Any confirmed point balance, coupons, or cash withdrawal must come from a verified backend and an ad contract permitting the specific rewards. Do not connect AdMob-style rewarded ads to cash or gift cards in violation of their policies.

**Scope:** Offerwall and paid social-follow campaigns are intentionally excluded.
