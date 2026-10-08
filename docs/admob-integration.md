# AdMob integration plan

TrisAdKit's `AdService` protocol and `MockAdService` are stable, SDK-independent foundations. Production advertising is **not enabled** yet.

## Integration boundaries

- Add a separate Google Mobile Ads-backed `AdService` implementation while keeping all AdMob types internal.
- The host application supplies its own AdMob application ID in `Info.plist` (`GADApplicationIdentifier`) and interstitial ad unit ID via injected configuration. Never commit production IDs as secrets.
- Use Google's **test interstitial ad unit** for development and automated UI smoke testing. Never click live advertisements for testing.
- Integrate UMP consent before initial ad requests; only request an ad if the SDK confirms `canRequestAds`. Provide an entry point for privacy options where required.
- Initialize Google Mobile Ads only after required consent/flags are handled.
- Preload one interstitial, show only at an eligible natural break, await dismissal/failure, then prepare the next ad.
- Use the host's topmost active view controller for presentation. Missing presenter, no-fill, network errors and dismissed/cancelled flows must return a safe result.
- Interstitial presentation cannot be the authority for saving or unlocking a workout report: persist sessions first; always allow reporting even when ads fail.
- Membership and app navigation stay in WakTrainerApp / TrisSubscriptionKit. TrisAdKit never queries the subscription state.

## App integration prerequisites

1. AdMob account, application registration and interstitial ad unit.
2. App privacy disclosure, SDK data mapping, UMP consent flow, and applicable ATT review.
3. Host Info.plist app ID and SKAdNetwork configuration following Google's current guide.
4. Privacy validation in applicable test regions, frequency policy and real-device test ads.
5. CI passing on package and consuming app before tag release.

## Official documentation

- https://developers.google.com/admob/ios/quick-start
- https://developers.google.com/admob/ios/interstitial
- https://developers.google.com/admob/ios/privacy
