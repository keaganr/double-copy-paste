// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DCPUI",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "DCPUI",
            targets: ["DCPUI"]
        ),
    ],
    dependencies: [
        .package(path: "../DCPClipboard"),
        .package(path: "../DCPModel"),
    ],
    targets: [
        .target(
            name: "DCPUI",
            dependencies: ["DCPClipboard", "DCPModel"]
        ),
        .testTarget(
            name: "DCPUITests",
            dependencies: ["DCPUI"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
