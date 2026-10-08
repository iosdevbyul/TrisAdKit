# Banner ads and external music

TrisAdKit supports two formats:

- `GoogleBannerAdView`: adaptive banner that can appear in SwiftUI layouts.
- `GoogleInterstitialAdService`: full-screen interstitial behind the existing `AdService` protocol.

## Audio protection

**Listening to music takes priority over ad revenue.** By default, interstitial presentation checks `AVAudioSession.sharedInstance().isOtherAudioPlaying`. If another app is already playing audio, the interstitial returns `.unavailable` without showing anything.

`GoogleBannerAdView` defaults to hiding the banner whenever external audio is detected on a SwiftUI update. Apps must drive SwiftUI updates when audio playback changes; simply checking inside `updateUIView` is not a continuous audio observer. For strict noninterruption guarantees, avoid loading banners when external music plays.

The `allowsAdvertisingAudio` banner override can disable that conservative skip; applications prioritizing music should keep the default `false`.

**Limitations:** Some mediated video ads may use their own audio session behavior. These safeguards avoid starting an interstitial while other audio is detected, but cannot guarantee that a newly started music session will not be affected by an advertisement already in progress. Verify on physical devices with Apple Music, Spotify, headphones and different mediated networks before declaring music uninterrupted.

Do not force-set AdMob `applicationMuted` or `applicationVolume = 0` purely to mute ads: Google documents that these values should reflect actual app audio controls and may reduce eligible inventory.

## Banner example

```swift
import SwiftUI
import TrisAdKit

GoogleBannerAdView(
    adUnitID: "ca-app-pub-3940256099942544/2435281174",
    width: 350,
    canRequestAds: { consent.canRequestAds }
)
.frame(height: 70)
```

Use the correct adaptive size when laying out the view; the above height is illustrative. `GoogleBannerAdView` is the SDK adapter, not the place to decide a host application's membership or advertising schedule.
