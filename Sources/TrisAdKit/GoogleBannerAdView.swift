import GoogleMobileAds
import SwiftUI
import UIKit

/// Adaptive AdMob banner for SwiftUI apps.
///
/// The host app may opt in to AdAudioSessionManager mixing before rendering ads.
@MainActor
public struct GoogleBannerAdView: UIViewRepresentable {
    public let adUnitID: String
    public let width: CGFloat
    public let canRequestAds: () -> Bool

    public init(
        adUnitID: String,
        width: CGFloat,
        canRequestAds: @escaping () -> Bool
    ) {
        self.adUnitID = adUnitID
        self.width = width
        self.canRequestAds = canRequestAds
    }

    public func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }

    public func updateUIView(_ container: UIView, context: Context) {
        let eligible = canRequestAds() && width > 0
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
