import Foundation

/// Serializes requests so the same interstitial is not presented twice.
@MainActor
public final class InterstitialAdController {
    private let service: any AdService
    private var isPresenting = false

    public init(service: any AdService) {
        self.service = service
    }

    public func prepare() async {
        await service.prepare()
    }

    public func presentIfAvailable() async -> AdPresentationResult {
        guard !isPresenting else { return .unavailable }
        isPresenting = true
        defer { isPresenting = false }
        return await service.presentInterstitialIfAvailable()
    }
}
