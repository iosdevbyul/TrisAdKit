import XCTest
@testable import TrisAdKit

@MainActor
private final class SuspendedAdService: AdService {
    private var continuation: CheckedContinuation<AdPresentationResult, Never>?
    private(set) var presentationCount = 0
    private(set) var preparationCount = 0

    func prepare() async {
        preparationCount += 1
    }

    func presentInterstitialIfAvailable() async -> AdPresentationResult {
        presentationCount += 1
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func complete(_ result: AdPresentationResult) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}

@MainActor
final class InterstitialLifecycleTests: XCTestCase {
    func testConcurrentRequestsCannotPresentSameAdTwice() async {
        let service = SuspendedAdService()
        let controller = InterstitialAdController(service: service)
        let first = Task { await controller.presentIfAvailable() }

        // Yield until the first request is suspended inside the service.
        for _ in 0..<100 where service.presentationCount == 0 {
            await Task.yield()
        }
        XCTAssertEqual(service.presentationCount, 1)

        let duplicate = await controller.presentIfAvailable()
        XCTAssertEqual(duplicate, .unavailable)
        XCTAssertEqual(service.presentationCount, 1)

        service.complete(.dismissed)
        let firstResult = await first.value
        XCTAssertEqual(firstResult, .dismissed)
    }

    func testFailureDoesNotLeaveControllerLocked() async {
        let mock = MockAdService(nextResult: .failed)
        let controller = InterstitialAdController(service: mock)
        let firstResult = await controller.presentIfAvailable()
        XCTAssertEqual(firstResult, .failed)
        mock.nextResult = .dismissed
        let secondResult = await controller.presentIfAvailable()
        XCTAssertEqual(secondResult, .dismissed)
        XCTAssertEqual(mock.presentationCallCount, 2)
    }

    func testUnavailableDoesNotLeaveControllerLocked() async {
        let mock = MockAdService(nextResult: .unavailable)
        let controller = InterstitialAdController(service: mock)
        let firstResult = await controller.presentIfAvailable()
        XCTAssertEqual(firstResult, .unavailable)
        mock.nextResult = .dismissed
        let secondResult = await controller.presentIfAvailable()
        XCTAssertEqual(secondResult, .dismissed)
    }

    func testFrequencyCapRequiresBothElapsedTimeAndOpportunities() {
        let limiter = AdFrequencyLimiter(
            policy: .init(minimumInterval: 60, minimumOpportunitiesBetweenAds: 3)
        )
        let start = Date(timeIntervalSince1970: 1000)
        XCTAssertTrue(limiter.shouldAttempt(at: start))
        limiter.recordPresentation(at: start)

        XCTAssertFalse(limiter.shouldAttempt(at: start.addingTimeInterval(61)))
        XCTAssertFalse(limiter.shouldAttempt(at: start.addingTimeInterval(62)))
        XCTAssertTrue(limiter.shouldAttempt(at: start.addingTimeInterval(63)))
    }

    func testFrequencyLimiterIgnoresNegativeConfiguration() {
        let policy = AdFrequencyPolicy(
            minimumInterval: -20,
            minimumOpportunitiesBetweenAds: -5
        )
        XCTAssertEqual(policy.minimumInterval, 0)
        XCTAssertEqual(policy.minimumOpportunitiesBetweenAds, 1)
    }

    func testNoPresentationMeansNoFrequencyCapReset() {
        let limiter = AdFrequencyLimiter(
            policy: .init(minimumInterval: 100, minimumOpportunitiesBetweenAds: 3)
        )
        let start = Date(timeIntervalSince1970: 500)
        XCTAssertTrue(limiter.shouldAttempt(at: start))
        // No recordPresentation call: failed/unavailable attempts should not lock.
        XCTAssertTrue(limiter.shouldAttempt(at: start.addingTimeInterval(1)))
    }
}
