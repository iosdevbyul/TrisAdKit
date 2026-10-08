# TrisAdKit

Reusable iOS 17+ Swift Package for interstitial ad orchestration with dependency injection.

## Included

- `AdService`: async main-actor contract for preparing and presenting an interstitial.
- `InterstitialAdController`: prevents concurrent presentations.
- `MockAdService`: configurable no-network service for UI previews and tests.
- `AdFrequencyLimiter`: optional app-owned time and opportunity caps.

The package **does not yet integrate Google Mobile Ads**. That implementation will be added behind `AdService` once SDK integration, consent handling, and test ad configuration are ready. Do not treat the mock as a revenue-generating advertisement.

## Usage

```swift
import TrisAdKit

@MainActor
func demo() async {
    let service = MockAdService()
    let controller = InterstitialAdController(service: service)
    await controller.prepare()
    _ = await controller.presentIfAvailable()
}
```

For a report-gating flow, the app must always persist completed workouts first. After an ad is dismissed, fails, or is unavailable, continue opening the report. Membership checks and screen navigation belong to the app, **not** the ad package.

## Development

```sh
xcodebuild -scheme TrisAdKit -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO test
```

PR CI runs on an available iPhone Simulator. No production ad IDs or secrets belong in this repository.
