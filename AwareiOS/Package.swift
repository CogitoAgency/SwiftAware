// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AwareiOS",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)  // Required for building on macOS host
    ],
    products: [
        .library(
            name: "AwareiOS",
            targets: ["AwareiOS"]
        ),
    ],
    dependencies: [
        .package(path: "../AwareCore")
    ],
    targets: [
        .target(
            name: "AwareiOS",
            dependencies: [
                .product(name: "AwareCore", package: "AwareCore")
            ],
            path: "Sources/AwareiOS",
            swiftSettings: [
                .define("AWARE_IOS"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AwareiOSTests",
            dependencies: ["AwareiOS"],
            path: "Tests/AwareiOSTests"
        ),
    ]
)
