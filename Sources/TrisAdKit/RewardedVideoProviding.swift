import Foundation

/// Rewarded video presentation is separate from reward settlement.
/// A provider callback is evidence of completion, not a cash balance.
public enum RewardedVideoResult: Equatable, Sendable {
    case completed
    case dismissed
    case unavailable
    case failed
}

@MainActor
public protocol RewardedVideoProviding: AnyObject {
    var providerName: String { get }
    func prepare() async
    func present() async -> RewardedVideoResult
}

/// Injectable integration boundary for TNK REVUP rewarded video.
/// The host supplies the approved REVUP SDK call after acquiring credentials.
@MainActor
public final class TNKRewardedVideoProvider: RewardedVideoProviding {
    public let providerName = "TNK REVUP"
    private let prepareHandler: @MainActor () async -> Void
    private let presentHandler: @MainActor () async -> RewardedVideoResult

    public init(
        prepare: @escaping @MainActor () async -> Void,
        present: @escaping @MainActor () async -> RewardedVideoResult
    ) {
        self.prepareHandler = prepare
        self.presentHandler = present
    }

    public func prepare() async { await prepareHandler() }
    public func present() async -> RewardedVideoResult { await presentHandler() }
}

@MainActor
public final class MockRewardedVideoProvider: RewardedVideoProviding {
    public let providerName = "Mock"
    public var nextResult: RewardedVideoResult
    public private(set) var presentationCount = 0

    public init(nextResult: RewardedVideoResult = .unavailable) {
        self.nextResult = nextResult
    }

    public func prepare() async {}
    public func present() async -> RewardedVideoResult {
        presentationCount += 1
        return nextResult
    }
}

@MainActor
public final class RewardedVideoCoordinator {
    private let provider: any RewardedVideoProviding
    private var isPresenting = false

    public init(provider: any RewardedVideoProviding) {
        self.provider = provider
    }

    public var providerName: String { provider.providerName }
    public func prepare() async { await provider.prepare() }

    public func present() async -> RewardedVideoResult {
        guard !isPresenting else { return .unavailable }
        isPresenting = true
        defer { isPresenting = false }
        return await provider.present()
    }
}
