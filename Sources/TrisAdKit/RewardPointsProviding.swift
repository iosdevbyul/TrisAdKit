import Foundation

/// A verified award from the app's trusted reward service.
public struct RewardPointEntry: Identifiable, Equatable, Sendable {
    public let id: String
    public let points: Int
    public let awardedAt: Date
    public let description: String

    public init(id: String, points: Int, awardedAt: Date, description: String) {
        self.id = id
        self.points = points
        self.awardedAt = awardedAt
        self.description = description
    }
}

/// A balance and ledger snapshot returned by a trusted backend.
/// A rewarded-video completion callback must never create entries directly.
public struct RewardPointsSnapshot: Equatable, Sendable {
    public let balance: Int
    public let entries: [RewardPointEntry]

    public init(balance: Int, entries: [RewardPointEntry]) {
        self.balance = balance
        self.entries = entries
    }
}

@MainActor
public protocol RewardPointsProviding: AnyObject {
    /// Fetch the server-authoritative confirmed balance and recent awards.
    func fetchConfirmedPoints() async throws -> RewardPointsSnapshot
}

/// Safe default until an approved advertiser and verification backend exist.
@MainActor
public final class UnconfiguredRewardPointsProvider: RewardPointsProviding {
    public init() {}

    public func fetchConfirmedPoints() async throws -> RewardPointsSnapshot {
        throw RewardPointsError.notConfigured
    }
}

public enum RewardPointsError: Error, Equatable, Sendable {
    case notConfigured
}

/// Test/preview implementation. Production apps must inject a trusted backend.
@MainActor
public final class MockRewardPointsProvider: RewardPointsProviding {
    public var snapshot: RewardPointsSnapshot
    public private(set) var fetchCount = 0

    public init(snapshot: RewardPointsSnapshot = RewardPointsSnapshot(balance: 0, entries: [])) {
        self.snapshot = snapshot
    }

    public func fetchConfirmedPoints() async throws -> RewardPointsSnapshot {
        fetchCount += 1
        return snapshot
    }
}
