// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DCPModel",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "DCPModel",
            targets: ["DCPModel"]
        ),
    ],
    targets: [
        .target(
            name: "DCPModel"
        ),
        .testTarget(
            name: "DCPModelTests",
            dependencies: ["DCPModel"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
