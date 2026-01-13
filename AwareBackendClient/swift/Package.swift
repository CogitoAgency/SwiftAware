// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AwareBackendClient",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AwareBackendClient",
            targets: ["AwareBackendClient"]
        ),
    ],
    dependencies: [
        .package(path: "../../AwareCore")
    ],
    targets: [
        .target(
            name: "AwareBackendClient",
            dependencies: [
                .product(name: "AwareCore", package: "AwareCore")
            ],
            path: "Sources/AwareBackendClient",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AwareBackendClientTests",
            dependencies: ["AwareBackendClient"],
            path: "Tests"
        ),
    ]
)
