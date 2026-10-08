import AVFAudio
import Foundation
import GoogleMobileAds
import UIKit

/// Production interstitial implementation. The host app must configure
/// GADApplicationIdentifier, obtain required consent, and provide an ad unit ID.
@MainActor
public final class GoogleInterstitialAdService: NSObject, AdService {
    private let adUnitID: String
    private let canRequestAds: @MainActor () -> Bool
    private let presenter: @MainActor () -> UIViewController?
    private let isOtherAudioPlaying: @MainActor () -> Bool
    private var loadedAd: InterstitialAd?
    private var isLoading = false
    private var continuation: CheckedContinuation<AdPresentationResult, Never>?

    public init(
        adUnitID: String,
        canRequestAds: @escaping @MainActor () -> Bool,
        presenter: @escaping @MainActor () -> UIViewController?,
        isOtherAudioPlaying: @escaping @MainActor () -> Bool = {
            AVAudioSession.sharedInstance().isOtherAudioPlaying
        }
    ) {
        self.adUnitID = adUnitID
        self.canRequestAds = canRequestAds
        self.presenter = presenter
        self.isOtherAudioPlaying = isOtherAudioPlaying
        super.init()
    }

    public func prepare() async {
        guard canRequestAds(), !isLoading, loadedAd == nil else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let ad = try await InterstitialAd.load(
                with: adUnitID,
                request: Request()
            )
            ad.fullScreenContentDelegate = self
            loadedAd = ad
        } catch {
            loadedAd = nil
        }
    }

    public func presentInterstitialIfAvailable() async -> AdPresentationResult {
        // Fail closed rather than risk interrupting a user's music.
        guard canRequestAds(),
              !isOtherAudioPlaying(),
              continuation == nil,
              let ad = loadedAd,
              let viewController = presenter() else {
            return .unavailable
        }

        do {
            try ad.canPresent(from: viewController)
        } catch {
            loadedAd = nil
            return .failed
        }

        loadedAd = nil
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            ad.present(from: viewController)
        }
    }

    private func finish(_ result: AdPresentationResult) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: result)
        Task { await prepare() }
    }
}

extension GoogleInterstitialAdService: FullScreenContentDelegate {
    public func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        finish(.dismissed)
    }

    public func ad(
        _ ad: any FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        finish(.failed)
    }
}
