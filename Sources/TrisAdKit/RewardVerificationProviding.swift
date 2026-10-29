import Foundation

/// A reward is confirmed only after the trusted service validates a provider
/// callback and commits its transaction to a deduplicated ledger.
public struct VerifiedRewardStatus: Decodable, Equatable, Sendable {
    public enum State: String, Decodable, Sendable {
        case pending
        case credited
        case rejected
    }
    public let transactionId: String
    public let state: State
    public let confirmedPoints: Int?
    public let balance: Int?
}

/// Public client-facing status API; never sends publisher signing credentials.
@MainActor
public protocol RewardVerificationProviding: AnyObject {
    func status(for transactionId: String) async throws -> VerifiedRewardStatus
}

/// Talks only to the application's own HTTPS backend, not directly to TNK.
/// The backend must verify the signed provider callback independently.
@MainActor
public final class RemoteRewardVerificationProvider: RewardVerificationProviding {
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

    public func status(for transactionId: String) async throws -> VerifiedRewardStatus {
        guard baseURL.scheme?.lowercased() == "https" else {
            throw RewardVerificationError.insecureEndpoint
        }
        guard !transactionId.isEmpty,
              let encoded = transactionId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              !encoded.contains("/") else {
            throw RewardVerificationError.invalidTransactionId
        }
        let url = baseURL.appendingPathComponent("v1/rewards/transactions")
            .appendingPathComponent(encoded)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("Bearer " + (try await authorization()), forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw RewardVerificationError.invalidResponse
        }
        let value = try JSONDecoder().decode(VerifiedRewardStatus.self, from: data)
        guard value.transactionId == transactionId else {
            throw RewardVerificationError.mismatchedTransaction
        }
        return value
    }
}

public enum RewardVerificationError: Error, Equatable, Sendable {
    case insecureEndpoint
    case invalidTransactionId
    case invalidResponse
    case mismatchedTransaction
}

@MainActor
public final class MockRewardVerificationProvider: RewardVerificationProviding {
    public var statuses: [String: VerifiedRewardStatus]
    public init(statuses: [String: VerifiedRewardStatus] = [:]) { self.statuses = statuses }

    public func status(for transactionId: String) async throws -> VerifiedRewardStatus {
        guard let result = statuses[transactionId] else {
            throw RewardVerificationError.invalidResponse
        }
        return result
    }
}
