// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AwareMacOS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AwareMacOS",
            targets: ["AwareMacOS"]
        ),
    ],
    dependencies: [
        .package(path: "../AwareCore")
    ],
    targets: [
        .target(
            name: "AwareMacOS",
            dependencies: [
                .product(name: "AwareCore", package: "AwareCore")
            ],
            path: "Sources/AwareMacOS",
            swiftSettings: [
                .define("AWARE_MACOS"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AwareMacOSTests",
            dependencies: ["AwareMacOS"],
            path: "Tests/AwareMacOSTests"
        ),
    ]
)
