import XCTest
@testable import TrisAdKit

@MainActor
final class RewardVerificationProvidingTests: XCTestCase {
    func testMockReturnsPendingThenCreditedState() async throws {
        let pending = VerifiedRewardStatus(transactionId: "tx-1", state: .pending, confirmedPoints: nil, balance: nil)
        let credited = VerifiedRewardStatus(transactionId: "tx-1", state: .credited, confirmedPoints: 5, balance: 25)
        let provider = MockRewardVerificationProvider(statuses: ["tx-1": pending])
        let first = try await provider.status(for: "tx-1")
        XCTAssertEqual(first.state, .pending)
        XCTAssertNil(first.confirmedPoints)

        provider.statuses["tx-1"] = credited
        let second = try await provider.status(for: "tx-1")
        XCTAssertEqual(second.state, .credited)
        XCTAssertEqual(second.balance, 25)
    }

    func testUnconfiguredTransactionDoesNotReturnFakeCredit() async {
        let provider = MockRewardVerificationProvider()
        do {
            _ = try await provider.status(for: "unseen")
            XCTFail("Unknown transactions must not be credited")
        } catch let error as RewardVerificationError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRejectsInsecureBackendBeforeRequest() async {
        let provider = RemoteRewardVerificationProvider(
            baseURL: URL(string: "http://example.invalid")!,
            authorization: { "test-token" }
        )
        do {
            _ = try await provider.status(for: "tx-1")
            XCTFail("HTTP endpoint must not be used")
        } catch let error as RewardVerificationError {
            XCTAssertEqual(error, .insecureEndpoint)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRejectsUnsafeTransactionIdBeforeRequest() async {
        let provider = RemoteRewardVerificationProvider(
            baseURL: URL(string: "https://example.invalid")!,
            authorization: { "test-token" }
        )
        do {
            _ = try await provider.status(for: "../other-user")
            XCTFail("Unsafe transaction identifiers must not be accepted")
        } catch let error as RewardVerificationError {
            XCTAssertEqual(error, .invalidTransactionId)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
