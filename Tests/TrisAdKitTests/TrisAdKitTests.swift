import XCTest
@testable import TrisAdKit

@MainActor
final class TrisAdKitTests: XCTestCase {
    func testMockAdServiceTracksCalls() async {
        let mock = MockAdService(nextResult: .dismissed)
        let controller = InterstitialAdController(service: mock)
        await controller.prepare()
        let result = await controller.presentIfAvailable()
        XCTAssertEqual(result, .dismissed)
        XCTAssertEqual(mock.prepareCallCount, 1)
        XCTAssertEqual(mock.presentationCallCount, 1)
    }

    func testUnavailableMockDoesNotBlock() async {
        let controller = InterstitialAdController(
            service: MockAdService(nextResult: .unavailable)
        )
        let result = await controller.presentIfAvailable()
        XCTAssertEqual(result, .unavailable)
    }

    func testFrequencyLimiter() {
        let limiter = AdFrequencyLimiter(
            policy: .init(minimumInterval: 60, minimumOpportunitiesBetweenAds: 3)
        )
        let start = Date(timeIntervalSince1970: 1000)
        XCTAssertTrue(limiter.shouldAttempt(at: start))
        limiter.recordPresentation(at: start)
        XCTAssertFalse(limiter.shouldAttempt(at: start.addingTimeInterval(10)))
        XCTAssertFalse(limiter.shouldAttempt(at: start.addingTimeInterval(40)))
        XCTAssertTrue(limiter.shouldAttempt(at: start.addingTimeInterval(61)))
    }

    func testTimeLimitDoesNotPreventLaterEligibleOpportunity() {
        let limiter = AdFrequencyLimiter(
            policy: .init(minimumInterval: 60, minimumOpportunitiesBetweenAds: 2)
        )
        let start = Date(timeIntervalSince1970: 1000)
        XCTAssertTrue(limiter.shouldAttempt(at: start))
        limiter.recordPresentation(at: start)
        XCTAssertFalse(limiter.shouldAttempt(at: start.addingTimeInterval(10)))
        XCTAssertFalse(limiter.shouldAttempt(at: start.addingTimeInterval(20)))
        XCTAssertTrue(limiter.shouldAttempt(at: start.addingTimeInterval(61)))
    }
}
