// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Aware",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Aware",
            targets: ["Aware"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.9.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0"),
        .package(url: "https://github.com/birdrides/mockingbird", from: "0.20.0")
    ],
    targets: [
        .target(
            name: "Aware",
            path: "Sources/Aware"
        ),
        .testTarget(
            name: "AwareTests",
            dependencies: [
                "Aware",
                "ViewInspector",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "Mockingbird", package: "mockingbird")
            ],
            path: "Tests/AwareTests"
        ),
    ]
)
