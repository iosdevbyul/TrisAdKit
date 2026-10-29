import XCTest
@testable import TrisAdKit

@MainActor
final class RewardPointsProvidingTests: XCTestCase {
    func testMockReturnsOnlyProvidedVerifiedLedger() async throws {
        let entry = RewardPointEntry(id: "txn-1", points: 15, awardedAt: Date(timeIntervalSince1970: 100), description: "광고 보상")
        let snapshot = RewardPointsSnapshot(balance: 115, entries: [entry])
        let provider = MockRewardPointsProvider(snapshot: snapshot)
        let result = try await provider.fetchConfirmedPoints()
        XCTAssertEqual(result, snapshot)
        XCTAssertEqual(provider.fetchCount, 1)
    }

    func testUnconfiguredProviderNeverGrantsPoints() async {
        let provider = UnconfiguredRewardPointsProvider()
        do {
            _ = try await provider.fetchConfirmedPoints()
            XCTFail("Unconfigured provider must not return an invented balance")
        } catch let error as RewardPointsError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
