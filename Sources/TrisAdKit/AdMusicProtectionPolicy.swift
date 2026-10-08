/// Audio behavior is independent of whether another app is playing music.
/// Both banner and interstitial advertisements remain eligible.
/// Clients can opt in to AdAudioSessionManager to request audio mixing.
@MainActor
public struct AdMusicProtectionPolicy {
    public init() {}

    public var canPresentFullscreenAd: Bool { true }
}
