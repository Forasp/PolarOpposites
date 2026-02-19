// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GiskardVision",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Renderer",
            targets: ["Renderer"]
        )
    ],
    targets: [
        .target(
            name: "Renderer"
        ),
        .testTarget(
            name: "RendererTests",
            dependencies: ["Renderer"]
        )
    ]
)
