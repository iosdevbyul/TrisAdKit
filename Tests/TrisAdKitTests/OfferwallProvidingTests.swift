import XCTest
@testable import TrisAdKit

@MainActor
final class OfferwallProvidingTests: XCTestCase {
    func testMockProviderDoesNotClaimRewards() async {
        let provider = MockOfferwallProvider(nextResult: .presented)
        let coordinator = OfferwallCoordinator(provider: provider)
        XCTAssertEqual(await coordinator.open(), .presented)
        XCTAssertEqual(provider.presentationCount, 1)
    }

    func testTNKAdapterUsesInjectedLauncher() async {
        var calls = 0
        let provider = TNKOfferwallProvider {
            calls += 1
            return .unavailable
        }
        let coordinator = OfferwallCoordinator(provider: provider)
        XCTAssertEqual(coordinator.providerName, "TNK")
        XCTAssertEqual(await coordinator.open(), .unavailable)
        XCTAssertEqual(calls, 1)
    }
}
