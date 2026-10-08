// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrisAdKit",
    platforms: [.iOS(.v17)],
    products: [.library(name: "TrisAdKit", targets: ["TrisAdKit"])],
    dependencies: [
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            exact: "13.11.0"
        ),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git",
            from: "3.0.0"
        )
    ],
    targets: [
        .target(
            name: "TrisAdKit",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                .product(name: "GoogleUserMessagingPlatform", package: "swift-package-manager-google-user-messaging-platform")
            ]
        ),
        .testTarget(name: "TrisAdKitTests", dependencies: ["TrisAdKit"])
    ]
)
