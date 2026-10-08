import AVFAudio
import Foundation

/// Explicit policy for preserving audio playing in other apps.
/// External audio is checked immediately before an interstitial is presented.
/// This is deliberately conservative: a skipped ad never blocks the host flow.
@MainActor
public struct AdMusicProtectionPolicy {
    private let isOtherAudioPlaying: () -> Bool

    public init(
        isOtherAudioPlaying: @escaping () -> Bool = {
            AVAudioSession.sharedInstance().isOtherAudioPlaying
        }
    ) {
        self.isOtherAudioPlaying = isOtherAudioPlaying
    }

    public var canPresentFullscreenAd: Bool {
        !isOtherAudioPlaying()
    }
}
