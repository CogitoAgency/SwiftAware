// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AwareTestHarness",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)  // Build on macOS host, target iOS
    ],
    products: [
        .executable(
            name: "AwareTestHarness",
            targets: ["AwareTestHarness"]
        ),
    ],
    dependencies: [
        .package(path: "../AwareCore"),
        .package(path: "../AwareiOS")
    ],
    targets: [
        .executableTarget(
            name: "AwareTestHarness",
            dependencies: [
                .product(name: "AwareCore", package: "AwareCore"),
                .product(name: "AwareiOS", package: "AwareiOS")
            ],
            path: "Sources/AwareTestHarness",
            swiftSettings: [
                .define("AWARE_TEST_HARNESS"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AwareTestHarnessTests",
            dependencies: ["AwareTestHarness"],
            path: "Tests/AwareTestHarnessTests"
        ),
    ]
)
