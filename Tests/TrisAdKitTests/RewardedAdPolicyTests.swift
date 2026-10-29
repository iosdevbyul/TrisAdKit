import XCTest
@testable import TrisAdKit

@MainActor
final class RewardedAdPolicyTests: XCTestCase {
    func testUnconfiguredPolicyDisablesAdvertising() async {
        let controller = RewardedAdPolicyController(provider: UnconfiguredRewardedAdPolicyProvider())
        let policy = await controller.refresh()
        XCTAssertFalse(policy.isEnabled)
        XCTAssertEqual(policy.dailyViewLimit, 0)
    }

    func testRemotePolicyCanBeSwappedThroughDI() async {
        let provider = MockRewardedAdPolicyProvider(
            policy: RewardedAdPolicy(
                isEnabled: true, dailyViewLimit: 3,
                minimumSecondsBetweenViews: 60, displayPointsPerView: 5
            )
        )
        let controller = RewardedAdPolicyController(provider: provider)
        let policy = await controller.refresh()
        XCTAssertTrue(policy.isEnabled)
        XCTAssertEqual(policy.dailyViewLimit, 3)
        XCTAssertEqual(policy.displayPointsPerView, 5)
        provider.policy = .disabled
        let disabled = await controller.refresh()
        XCTAssertFalse(disabled.isEnabled)
    }

    func testPolicyClampsNegativeLimits() {
        let policy = RewardedAdPolicy(
            isEnabled: true, dailyViewLimit: -1,
            minimumSecondsBetweenViews: -20, displayPointsPerView: -5
        )
        XCTAssertEqual(policy.dailyViewLimit, 0)
        XCTAssertEqual(policy.minimumSecondsBetweenViews, 0)
        XCTAssertEqual(policy.displayPointsPerView, 0)
    }
}
