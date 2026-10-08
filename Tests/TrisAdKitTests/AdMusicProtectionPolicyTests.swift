import XCTest
@testable import TrisAdKit

@MainActor
final class AdMusicProtectionPolicyTests: XCTestCase {
    func testSkipsInterstitialWhileExternalMusicIsPlaying() {
        let policy = AdMusicProtectionPolicy(isOtherAudioPlaying: { true })
        XCTAssertFalse(policy.canPresentFullscreenAd)
    }

    func testAllowsInterstitialWhenNoExternalMusicIsPlaying() {
        let policy = AdMusicProtectionPolicy(isOtherAudioPlaying: { false })
        XCTAssertTrue(policy.canPresentFullscreenAd)
    }

    func testInterstitialIsSkippedWhileExternalMusicIsPlaying() async {
        let service = GoogleInterstitialAdService(
            adUnitID: "ca-app-pub-3940256099942544/4411468910",
            canRequestAds: { true },
            presenter: { nil },
            isOtherAudioPlaying: { true }
        )
        let result = await service.presentInterstitialIfAvailable()
        XCTAssertEqual(result, .unavailable)
    }
}
