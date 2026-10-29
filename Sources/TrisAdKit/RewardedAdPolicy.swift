import Foundation

/// Server-controlled eligibility settings, not proof of a payable reward.
public struct RewardedAdPolicy: Codable, Equatable, Sendable {
    public let isEnabled: Bool
    public let dailyViewLimit: Int
    public let minimumSecondsBetweenViews: Int
    public let displayPointsPerView: Int

    public init(isEnabled: Bool, dailyViewLimit: Int, minimumSecondsBetweenViews: Int, displayPointsPerView: Int) {
        self.isEnabled = isEnabled
        self.dailyViewLimit = max(0, dailyViewLimit)
        self.minimumSecondsBetweenViews = max(0, minimumSecondsBetweenViews)
        self.displayPointsPerView = max(0, displayPointsPerView)
    }

    public static let disabled = RewardedAdPolicy(
        isEnabled: false, dailyViewLimit: 0,
        minimumSecondsBetweenViews: 0, displayPointsPerView: 0
    )
}

@MainActor
public protocol RewardedAdPolicyProviding: AnyObject {
    func fetchPolicy() async throws -> RewardedAdPolicy
}

/// Does not enable ads until a trusted configuration service is connected.
@MainActor
public final class UnconfiguredRewardedAdPolicyProvider: RewardedAdPolicyProviding {
    public init() {}
    public func fetchPolicy() async throws -> RewardedAdPolicy { .disabled }
}

/// Use for deterministic tests and previews only.
@MainActor
public final class MockRewardedAdPolicyProvider: RewardedAdPolicyProviding {
    public var policy: RewardedAdPolicy
    public init(policy: RewardedAdPolicy = .disabled) { self.policy = policy }
    public func fetchPolicy() async throws -> RewardedAdPolicy { policy }
}

/// Fetches policy from an app-authorized HTTPS endpoint. No credentials or URLs
/// are hardcoded in the shared package.
@MainActor
public final class RemoteRewardedAdPolicyProvider: RewardedAdPolicyProviding {
    private let endpoint: URL
    private let session: URLSession

    public init(endpoint: URL, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    public func fetchPolicy() async throws -> RewardedAdPolicy {
        guard endpoint.scheme?.lowercased() == "https" else {
            throw RewardedAdPolicyError.insecureEndpoint
        }
        var request = URLRequest(url: endpoint)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw RewardedAdPolicyError.invalidResponse
        }
        return try JSONDecoder().decode(RewardedAdPolicy.self, from: data)
    }
}

public enum RewardedAdPolicyError: Error, Equatable, Sendable {
    case insecureEndpoint
    case invalidResponse
}

/// A fetch failure must never enable advertising using stale or invented policy.
@MainActor
public final class RewardedAdPolicyController {
    private let provider: any RewardedAdPolicyProviding
    public private(set) var policy: RewardedAdPolicy = .disabled

    public init(provider: any RewardedAdPolicyProviding) { self.provider = provider }

    @discardableResult
    public func refresh() async -> RewardedAdPolicy {
        do {
            policy = try await provider.fetchPolicy()
        } catch {
            policy = .disabled
        }
        return policy
    }
}
