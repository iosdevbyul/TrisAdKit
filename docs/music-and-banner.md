# Ad audio behavior

TrisAdKit **does not suppress ads** when another application plays music.
Banner and interstitial eligibility depend on consent, ad availability and
presentation state only.

### Preferred audio mixing (opt-in)

```swift
import TrisAdKit

let audio = AdAudioSessionManager()
let result = audio.configurePreferredMixing()
```

`configurePreferredMixing()` configures the process-wide iOS audio session
using `.ambient`, which supports mixing with other apps' audio, and tells
Google Mobile Ads to let the application manage the audio session. Neither
`duckOthers` nor an ad mute override is used.

If the session cannot be configured, the method returns
`.sdkManagedFallback` and leaves audio management to the Google SDK.
The ad will still be eligible for display.

**Host app responsibility:** `AVAudioSession` is shared across the app.
Do not call this method blindly in an app that already manages an audio session
(e.g., voice chat or a workout coaching player); coordinate session ownership
at the application boundary. `useSDKManagedAudio()` returns management to
the Google SDK without rewriting the app's audio session.

**Limitations:** SDK mediation, third-party ad creatives, AirPlay, Bluetooth
routes and other audio-session owners can behave differently. Mixing is a
best-effort preference, **not a guarantee** that external playback never stops.
Verify with Apple Music / Spotify on physical devices before claiming guaranteed
coexistence.

Documentation: https://developers.google.com/admob/ios/global-settings

## Banner

```swift
GoogleBannerAdView(
    adUnitID: "ca-app-pub-3940256099942544/2435281174",
    width: 350,
    canRequestAds: { consent.canRequestAds }
)
```

## Interstitial

`GoogleInterstitialAdService` no longer takes
`isOtherAudioPlaying`. It never skips an advertisement because of music.
