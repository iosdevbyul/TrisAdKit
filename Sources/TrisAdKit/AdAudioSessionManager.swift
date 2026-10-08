import AVFAudio
import GoogleMobileAds

/// Opt-in audio-session configuration for apps that want ad audio mixed
/// with audio from other apps, without pausing or ducking that audio.
///
/// Call once during app setup, before starting ad playback. Because
/// AVAudioSession is process-wide, this changes the host app's audio category.
/// Apps with their own audio engine should coordinate this with their existing
/// audio-session owner rather than configuring both independently.
@MainActor
public final class AdAudioSessionManager {
    public enum ConfigurationResult: Equatable {
        case mixingEnabled
        case sdkManagedFallback
    }

    public init() {}

    /// If configuring a mixing category fails, keep the Google SDK in charge
    /// of its own audio session and do not block advertisements.
    @discardableResult
    public func configurePreferredMixing() -> ConfigurationResult {
        let manager = MobileAds.shared.audioVideoManager
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default
            )
            manager.isAudioSessionApplicationManaged = true
            return .mixingEnabled
        } catch {
            manager.isAudioSessionApplicationManaged = false
            return .sdkManagedFallback
        }
    }

    /// Return control to Google's SDK when the host no longer wants to
    /// manage ad audio. Does not change the host audio-session category.
    public func useSDKManagedAudio() {
        MobileAds.shared.audioVideoManager.isAudioSessionApplicationManaged = false
    }
}
