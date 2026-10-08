import Foundation

/// An application-controlled frequency cap for natural transition points.
/// This counts eligible opportunities, not impressions or clicks.
public struct AdFrequencyPolicy: Sendable {
    public let minimumInterval: TimeInterval
    public let minimumOpportunitiesBetweenAds: Int

    public init(
        minimumInterval: TimeInterval = 180,
        minimumOpportunitiesBetweenAds: Int = 3
    ) {
        self.minimumInterval = max(0, minimumInterval)
        self.minimumOpportunitiesBetweenAds = max(1, minimumOpportunitiesBetweenAds)
    }
}

@MainActor
public final class AdFrequencyLimiter {
    private let policy: AdFrequencyPolicy
    private var lastPresentationDate: Date?
    private var opportunityCount = 0

    public init(policy: AdFrequencyPolicy = .init()) {
        self.policy = policy
    }

    public func shouldAttempt(at date: Date = Date()) -> Bool {
        opportunityCount += 1
        guard let lastPresentationDate else { return true }
        return opportunityCount >= policy.minimumOpportunitiesBetweenAds &&
            date.timeIntervalSince(lastPresentationDate) >= policy.minimumInterval
    }

    /// Call only after an ad has actually been presented and dismissed.
    public func recordPresentation(at date: Date = Date()) {
        lastPresentationDate = date
        opportunityCount = 0
    }
}
