import XCTest
@testable import TrisAdKit

@MainActor
final class GoogleAdAdapterTests: XCTestCase {
    func testDeniedConsentDoesNotLoadOrPresentAd() async {
        let service = GoogleInterstitialAdService(
            adUnitID: "ca-app-pub-3940256099942544/4411468910",
            canRequestAds: { false },
            presenter: { nil }
        )
        await service.prepare()
        let result = await service.presentInterstitialIfAvailable()
        XCTAssertEqual(result, .unavailable)
    }
}
