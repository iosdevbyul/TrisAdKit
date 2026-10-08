import Foundation

/// Possible results of one advertisement presentation attempt.
public enum AdPresentationResult: Equatable, Sendable {
    case dismissed
    case unavailable
    case failed
}

/// Implementations own the advertisement SDK and presentation lifecycle.
/// Returns only after an advertisement is dismissed or an attempt fails.
@MainActor
public protocol AdService: AnyObject {
    func prepare() async
    func presentInterstitialIfAvailable() async -> AdPresentationResult
}

/// In-memory implementation for previews, tests and apps without a configured ad network.
/// Does not require internet access or an advertising account.
@MainActor
public final class MockAdService: AdService {
    public var nextResult: AdPresentationResult
    public private(set) var prepareCallCount = 0
    public private(set) var presentationCallCount = 0

    public init(nextResult: AdPresentationResult = .dismissed) {
        self.nextResult = nextResult
    }

    public func prepare() async {
        prepareCallCount += 1
    }

    public func presentInterstitialIfAvailable() async -> AdPresentationResult {
        presentationCallCount += 1
        return nextResult
    }
}
