# Google AdMob adapter

`GoogleInterstitialAdService` uses Google's official interstitial SDK and remains behind the existing `AdService` protocol. The existing `MockAdService` continues to support previews and offline tests.

## Requirements

- Xcode 16+ and iOS 17+.
- Host app registers an AdMob app ID in Info.plist under `GADApplicationIdentifier`.
- Host app provides its own ad unit ID, scene-appropriate visible view controller, and UMP consent manager.
- Call `GoogleAdConsentManager.prepareConsent()` when launching the app and respect `canRequestAds` before loading.
- Configure `MobileAds.shared.start()` in the **host app** after the consent workflow and before making the first ad request.
- Use Google's sample interstitial ID `ca-app-pub-3940256099942544/4411468910` for development only.
- Provide a privacy settings entry point when `requiresPrivacyOptions` is true.
- Before App Store release, review App Privacy, ATT applicability and SKAdNetwork identifiers.

## Usage

```swift
import TrisAdKit
import GoogleMobileAds

let consent = GoogleAdConsentManager()

// Call once per app launch at an appropriate UI transition.
try await consent.prepareConsent()
if consent.canRequestAds {
    MobileAds.shared.start()
}

let service = GoogleInterstitialAdService(
    adUnitID: "ca-app-pub-3940256099942544/4411468910",
    canRequestAds: { consent.canRequestAds },
    presenter: { activeViewController }
)

let controller = InterstitialAdController(service: service)
await controller.prepare()

// Only at a natural screen transition, after persisting workout data:
_ = await controller.presentIfAvailable()
// Regardless of the result, continue to the report.
```

The `activeViewController` symbol stands for the current presenting view controller, supplied by the app; it is not a built-in TrisAdKit implementation. Membership checks and advertising frequency limits are app-owned decisions.

## Notes

The SDK needs an internet connection to load live ads. When unavailable, `presentIfAvailable()` returns `.unavailable`. The SDK never controls workout persistence or access to saved reports.
