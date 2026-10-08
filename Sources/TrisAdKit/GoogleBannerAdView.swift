import AVFAudio
import GoogleMobileAds
import SwiftUI
import UIKit

/// Adaptive AdMob banner for SwiftUI apps.
///
/// Banner content can include video. To protect externally playing audio,
/// the view removes the ad when other audio is detected during SwiftUI updates.
/// The app must also invoke an update when its audio state changes.
/// For strict uninterrupted music, avoid banner display while external audio plays.
@MainActor
public struct GoogleBannerAdView: UIViewRepresentable {
    public let adUnitID: String
    public let width: CGFloat
    public let canRequestAds: () -> Bool
    public let allowsAdvertisingAudio: Bool

    public init(
        adUnitID: String,
        width: CGFloat,
        canRequestAds: @escaping () -> Bool,
        allowsAdvertisingAudio: Bool = false
    ) {
        self.adUnitID = adUnitID
        self.width = width
        self.canRequestAds = canRequestAds
        self.allowsAdvertisingAudio = allowsAdvertisingAudio
    }

    public func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }

    public func updateUIView(_ container: UIView, context: Context) {
        let externalAudio = AVAudioSession.sharedInstance().isOtherAudioPlaying
        let eligible = canRequestAds() && width > 0
            && (allowsAdvertisingAudio || !externalAudio)
        guard eligible else {
            container.subviews.forEach { $0.removeFromSuperview() }
            return
        }

        if let existing = container.subviews.first as? BannerView,
           existing.adUnitID == adUnitID {
            let size = largeAnchoredAdaptiveBanner(width: width)
            if existing.adSize.size != size.size {
                existing.adSize = size
                existing.load(Request())
            }
            return
        }

        container.subviews.forEach { $0.removeFromSuperview() }
        let banner = BannerView()
        banner.adUnitID = adUnitID
        banner.adSize = largeAnchoredAdaptiveBanner(width: width)
        banner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            banner.topAnchor.constraint(equalTo: container.topAnchor),
            banner.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        banner.load(Request())
    }
}
