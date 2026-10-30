import Foundation

/// Reads confirmed balances from the reward ledger service using a host-provided
/// application session token. Does not authenticate users or award points.
@MainActor
public final class RemoteRewardPointsProvider: RewardPointsProviding {
    private let baseURL: URL
    private let session: URLSession
    private let authorization: @MainActor () async throws -> String

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        authorization: @escaping @MainActor () async throws -> String
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authorization = authorization
    }

    public func fetchConfirmedPoints() async throws -> RewardPointsSnapshot {
        guard baseURL.scheme?.lowercased() == "https" else {
            throw RemoteRewardPointsError.insecureEndpoint
        }
        let token = try await authorization()
        guard !token.isEmpty else {
            throw RemoteRewardPointsError.missingAuthorization
        }
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/rewards/points"))
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw RemoteRewardPointsError.invalidResponse
        }

        let payload = try JSONDecoder().decode(Payload.self, from: data)
        guard payload.balance >= 0, payload.entries.allSatisfy({ $0.points > 0 }) else {
            throw RemoteRewardPointsError.invalidResponse
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let entries = try payload.entries.map { item -> RewardPointEntry in
            guard let date = formatter.date(from: item.awardedAt) ??
                ISO8601DateFormatter().date(from: item.awardedAt) else {
                throw RemoteRewardPointsError.invalidResponse
            }
            return RewardPointEntry(
                id: item.id, points: item.points, awardedAt: date,
                description: item.description
            )
        }
        return RewardPointsSnapshot(balance: payload.balance, entries: entries)
    }

    private struct Payload: Decodable {
        let balance: Int
        let entries: [Entry]
    }

    private struct Entry: Decodable {
        let id: String
        let points: Int
        let awardedAt: String
        let description: String
    }
}

public enum RemoteRewardPointsError: Error, Equatable, Sendable {
    case insecureEndpoint
    case missingAuthorization
    case invalidResponse
}
