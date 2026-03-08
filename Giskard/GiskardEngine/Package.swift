// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GiskardEngine",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GiskardEngine",
            targets: ["GiskardEngine"]
        )
    ],
    dependencies: [
        .package(path: "../GiskardVision")
    ],
    targets: [
        .target(
            name: "GiskardEngine",
            dependencies: [
                .product(name: "Renderer", package: "GiskardVision")
            ]
        ),
        .testTarget(
            name: "GiskardEngineTests",
            dependencies: ["GiskardEngine"]
        )
    ]
)
