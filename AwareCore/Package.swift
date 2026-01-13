// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AwareCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AwareCore",
            targets: ["AwareCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AwareCore",
            dependencies: [],
            path: "Sources/AwareCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AwareCoreTests",
            dependencies: ["AwareCore"],
            path: "Tests/AwareCoreTests"
        ),
    ]
)
