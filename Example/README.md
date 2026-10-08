# TrisAdKitDemo

Standalone iOS 17+ demo of the local `TrisAdKit` package. No WakTrainerApp integration is necessary.

## Run

1. Open `Example/TrisAdKitDemo.xcodeproj` in Xcode.
2. Choose the shared `TrisAdKitDemo` scheme and an iOS simulator or a signed iPhone.
3. Tap **Request consent / initialize SDK** before requesting any advertisement.
4. Test the adaptive banner, preload/show the interstitial and view result messages.
5. On a physical device, play Apple Music or Spotify before tapping **Prefer mixing with external music**, then show the test interstitial. Compare to **Use Google SDK audio defaults**.

This demo uses **Google's sample AdMob application ID and sample ad unit IDs exclusively**. It does not require the developer's personal AdMob account and is not connected to live revenue.

Notes: On-device SDK behavior and music continuity must be verified in person; the CI demo build validates compilation, not advertising availability or cross-app audio guarantees. Consent prompts vary by test region. The audio-session configuration is process-wide; use only with a compatible host audio session.
