// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AwareBridge",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AwareBridge",
            targets: ["AwareBridge"]
        ),
    ],
    dependencies: [
        .package(path: "../AwareCore")
    ],
    targets: [
        .target(
            name: "AwareBridge",
            dependencies: [
                .product(name: "AwareCore", package: "AwareCore")
            ],
            path: "Sources/AwareBridge",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AwareBridgeTests",
            dependencies: ["AwareBridge"],
            path: "Tests"
        ),
    ]
)
