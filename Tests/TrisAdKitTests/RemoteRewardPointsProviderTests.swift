import Foundation
import XCTest
@testable import TrisAdKit

private final class PointsURLProtocol: URLProtocol {
    static let lock = NSLock()
    static var responseData = Data()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let data = Self.lock.withLock { Self.responseData }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(
            url: request.url!, statusCode: 200, httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@MainActor
final class RemoteRewardPointsProviderTests: XCTestCase {
    func testRejectsInsecureURL() async {
        let provider = RemoteRewardPointsProvider(
            baseURL: URL(string: "http://localhost:8765")!,
            authorization: { "test-token" }
        )
        do {
            _ = try await provider.fetchConfirmedPoints()
            XCTFail("An insecure endpoint must be rejected")
        } catch let error as RemoteRewardPointsError {
            XCTAssertEqual(error, .insecureEndpoint)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRejectsMissingSession() async {
        let provider = RemoteRewardPointsProvider(
            baseURL: URL(string: "https://example.invalid")!,
            authorization: { "" }
        )
        do {
            _ = try await provider.fetchConfirmedPoints()
            XCTFail("A missing session must not be accepted")
        } catch let error as RemoteRewardPointsError {
            XCTAssertEqual(error, .missingAuthorization)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDecodesAuthoritativeLedgerSnapshot() async throws {
        PointsURLProtocol.lock.withLock {
            PointsURLProtocol.responseData = Data(
                """
                {"balance":12,"entries":[{"id":"tnk:tx1","points":12,"awardedAt":"2026-10-30T00:00:00.123456+00:00","description":"Verified rewarded video"}]}
                """.utf8
            )
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [PointsURLProtocol.self]
        let provider = RemoteRewardPointsProvider(
            baseURL: URL(string: "https://example.invalid")!,
            session: URLSession(configuration: config),
            authorization: { "test-token" }
        )
        let snapshot = try await provider.fetchConfirmedPoints()
        XCTAssertEqual(snapshot.balance, 12)
        XCTAssertEqual(snapshot.entries.count, 1)
        XCTAssertEqual(snapshot.entries.first?.id, "tnk:tx1")
    }
}
