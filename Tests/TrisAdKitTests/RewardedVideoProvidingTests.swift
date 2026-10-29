import XCTest
@testable import TrisAdKit

@MainActor
final class RewardedVideoProvidingTests: XCTestCase {
    func testMockProviderReportsCompletionWithoutAwardingPoints() async {
        let provider = MockRewardedVideoProvider(nextResult: .completed)
        let coordinator = RewardedVideoCoordinator(provider: provider)
        let result = await coordinator.present()
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(provider.presentationCount, 1)
    }

    func testTNKAdapterIsInjectable() async {
        var prepareCalls = 0
        var presentCalls = 0
        let provider = TNKRewardedVideoProvider(
            prepare: { prepareCalls += 1 },
            present: {
                presentCalls += 1
                return .unavailable
            }
        )
        let coordinator = RewardedVideoCoordinator(provider: provider)
        XCTAssertEqual(coordinator.providerName, "TNK REVUP")
        await coordinator.prepare()
        let result = await coordinator.present()
        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(prepareCalls, 1)
        XCTAssertEqual(presentCalls, 1)
    }
}
