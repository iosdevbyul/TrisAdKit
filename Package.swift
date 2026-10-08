// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrisAdKit",
    platforms: [.iOS(.v17)],
    products: [.library(name: "TrisAdKit", targets: ["TrisAdKit"])],
    targets: [
        .target(name: "TrisAdKit"),
        .testTarget(name: "TrisAdKitTests", dependencies: ["TrisAdKit"])
    ]
)
