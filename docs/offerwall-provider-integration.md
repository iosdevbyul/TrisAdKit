# Offerwall provider integration

TrisAdKit owns presentation and DI; applications import only `TrisAdKit`.

## TNK first, other providers later

```swift
import TrisAdKit

let provider = TNKOfferwallProvider {
    // Use the approved TNK iOS SDK after configuring the publisher app ID,
    // stable user ID and test device. Return .presented only when launched.
    return .unavailable
}
let coordinator = OfferwallCoordinator(provider: provider)
let result = await coordinator.open()
```

The official TNK RWD2 documentation references `TnkRwdSdk2`,
`TnkSession.initInstance(appId:)`, `setUserName`, and
`AdOfferwallViewController`. TNK Reward Plus uses `LgRwdPlus` and has
separate account and app configuration requirements. Choose the contracted
product before adding its binary framework and integration target.

Documentation:
- https://github.com/tnkfactory/ios-sdk-rwd2/blob/main/iOS_Guide.md
- https://github.com/tnkfactory/ios-sdk-rwd2/blob/main/RwdPlusGuide.md

No TNK framework, production credentials, account identity or publisher
approval is included in the package yet. No revenue or redemption is live.

## Security boundary

A completed ad view or user tap is not evidence of an earned reward.
The confirmed balance must come from the authorized provider/backend
callback; never allow the UI to mint redeemable points locally. Cash or
gift-card redemption requires the contracted ad product and settlement flow.
