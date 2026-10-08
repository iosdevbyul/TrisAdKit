import XCTest
@testable import TrisAdKit

@MainActor
final class AdMusicProtectionPolicyTests: XCTestCase {
    func testAudioPolicyDoesNotSkipAds() {
        let policy = AdMusicProtectionPolicy()
        XCTAssertTrue(policy.canPresentFullscreenAd)
    }

    func testInterstitialIsUnavailableOnlyWithoutLoadedAd() async {
        let service = GoogleInterstitialAdService(
            adUnitID: "ca-app-pub-3940256099942544/4411468910",
            canRequestAds: { true },
            presenter: { nil }
        )
        // No ad is loaded; external audio is never used as a blocking condition.
        let result = await service.presentInterstitialIfAvailable()
        XCTAssertEqual(result, .unavailable)
    }
}
