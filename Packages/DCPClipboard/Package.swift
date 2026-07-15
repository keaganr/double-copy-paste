// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DCPClipboard",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "DCPClipboard",
            targets: ["DCPClipboard"]
        ),
    ],
    dependencies: [
        .package(path: "../DCPModel"),
    ],
    targets: [
        .target(
            name: "DCPClipboard",
            dependencies: ["DCPModel"]
        ),
        .testTarget(
            name: "DCPClipboardTests",
            dependencies: ["DCPClipboard"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
