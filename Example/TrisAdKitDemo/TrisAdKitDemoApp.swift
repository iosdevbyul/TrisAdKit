import SwiftUI
import GoogleMobileAds
import TrisAdKit

@main
struct TrisAdKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            AdDemoView()
        }
    }
}

@MainActor
private struct AdDemoView: View {
    @State private var consent = GoogleAdConsentManager()
    @State private var audioManager = AdAudioSessionManager()
    @State private var interstitial: GoogleInterstitialAdService?
    @State private var status = "Not initialized"
    @State private var isPreparing = false
    @State private var canRequestAds = false
    @State private var isSDKStarted = false

    private let interstitialTestID = "ca-app-pub-3940256099942544/4411468910"
    private let bannerTestID = "ca-app-pub-3940256099942544/2435281174"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("TrisAdKit Demo").font(.largeTitle.bold())
                Text("Google sample ads only. No production ad units.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                GroupBox("Consent & SDK") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Consent allows requests: \(canRequestAds ? "Yes" : "No")")
                        Button("Request consent / initialize SDK") {
                            Task { await initialize() }
                        }
                        .disabled(isPreparing)
                        if consent.requiresPrivacyOptions {
                            Button("Privacy options") {
                                Task {
                                    do {
                                        try await consent.presentPrivacyOptions()
                                        canRequestAds = consent.canRequestAds
                                    } catch {
                                        status = "Privacy options: \(error.localizedDescription)"
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Audio") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Prefer mixing with external music") {
                            let outcome = audioManager.configurePreferredMixing()
                            status = "Audio: \(String(describing: outcome))"
                        }
                        Button("Use Google SDK audio defaults") {
                            audioManager.useSDKManagedAudio()
                            status = "SDK-managed audio"
                        }
                        Text("Play music in another app before testing video ads.")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Interstitial") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Preload test interstitial") {
                            Task {
                                guard let interstitial else { return }
                                await interstitial.prepare()
                                status = "Interstitial preload finished"
                            }
                        }
                        Button("Show test interstitial") {
                            Task {
                                guard let interstitial else { return }
                                let result = await interstitial.presentInterstitialIfAvailable()
                                status = "Interstitial: \(String(describing: result))"
                            }
                        }
                        Text("Ads are not skipped because of external music.")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .disabled(!canRequestAds || !isSDKStarted)
                }

                GroupBox("Adaptive banner") {
                    GeometryReader { geo in
                        if canRequestAds && isSDKStarted {
                            GoogleBannerAdView(
                                adUnitID: bannerTestID,
                                width: geo.size.width,
                                canRequestAds: { consent.canRequestAds }
                            )
                        } else {
                            Text("Initialize consent first")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 110)
                }

                Text(status)
                    .font(.footnote.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("adStatus")
            }
            .padding()
        }
        .task {
            interstitial = GoogleInterstitialAdService(
                adUnitID: interstitialTestID,
                canRequestAds: { consent.canRequestAds },
                presenter: { topViewController() }
            )
        }
    }

    private func initialize() async {
        guard !isPreparing else { return }
        isPreparing = true
        defer { isPreparing = false }
        do {
            try await consent.prepareConsent(from: topViewController())
            canRequestAds = consent.canRequestAds
            if canRequestAds {
                if !isSDKStarted {
                    await MobileAds.shared.start()
                    isSDKStarted = true
                }
                await interstitial?.prepare()
                status = "SDK ready; test interstitial requested"
            } else {
                status = "Consent not available; no ad requests"
            }
        } catch {
            // UMP may still permit requests with cached consent after errors.
            canRequestAds = consent.canRequestAds
            status = "Consent update error: \(error.localizedDescription)"
        }
    }

    private func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }
        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}
