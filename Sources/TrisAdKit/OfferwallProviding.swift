import Foundation
import UIKit

/// Allows the host to swap offerwall vendors without changing feature screens.
@MainActor
public protocol OfferwallProviding: AnyObject {
    var providerName: String { get }
    func presentOfferwall() async -> OfferwallPresentationResult
}

public enum OfferwallPresentationResult: Equatable, Sendable {
    case presented
    case unavailable
    case failed
}

/// Deterministic provider for previews, CI and apps without an ad contract.
@MainActor
public final class MockOfferwallProvider: OfferwallProviding {
    public let providerName = "Mock"
    public var nextResult: OfferwallPresentationResult
    public private(set) var presentationCount = 0

    public init(nextResult: OfferwallPresentationResult = .unavailable) {
        self.nextResult = nextResult
    }

    public func presentOfferwall() async -> OfferwallPresentationResult {
        presentationCount += 1
        return nextResult
    }
}

/// TNK integration boundary. The actual TNK framework, app ID and user ID
/// are supplied by the composition root after publisher approval.
/// This adapter never claims a reward was earned on UI presentation alone.
@MainActor
public final class TNKOfferwallProvider: OfferwallProviding {
    public let providerName = "TNK"
    private let launcher: @MainActor () async -> OfferwallPresentationResult

    public init(launcher: @escaping @MainActor () async -> OfferwallPresentationResult) {
        self.launcher = launcher
    }

    public func presentOfferwall() async -> OfferwallPresentationResult {
        await launcher()
    }
}

/// The host chooses the provider once; other screens depend only on the protocol.
@MainActor
public final class OfferwallCoordinator {
    private let provider: any OfferwallProviding
    private var presenting = false

    public init(provider: any OfferwallProviding) {
        self.provider = provider
    }

    public var providerName: String { provider.providerName }

    public func open() async -> OfferwallPresentationResult {
        guard !presenting else { return .unavailable }
        presenting = true
        defer { presenting = false }
        return await provider.presentOfferwall()
    }
}
