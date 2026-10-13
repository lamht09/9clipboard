// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NineClipboard",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "NineClipboard", targets: ["NineClipboard"]),
        .library(name: "ClipCore", targets: ["ClipCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "ClipCore",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")],
            // NSAttributedString(rtf:) là category của AppKit; bundle test không tự nạp AppKit.
            linkerSettings: [.linkedFramework("AppKit")]
        ),
        .executableTarget(
            name: "NineClipboard",
            dependencies: ["ClipCore"]
        ),
        .testTarget(
            name: "ClipCoreTests",
            dependencies: ["ClipCore"]
        ),
    ]
)
