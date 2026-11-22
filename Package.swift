// swift-tools-version: 6.0
import Foundation
import PackageDescription

// The Command Line Tools ship Swift Testing, but its macro plugin is not on the default plugin path.
// Xcode finds it on its own, so the flag is only added when Xcode is absent.
let cltTestingPlugins = "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing"
let testSettings: [SwiftSetting] =
    !FileManager.default.fileExists(atPath: "/Applications/Xcode.app")
        && FileManager.default.fileExists(atPath: cltTestingPlugins)
    ? [.unsafeFlags(["-plugin-path", cltTestingPlugins])]
    : []

let package = Package(
    name: "SimpleTile",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "SimpleTileCore"),
        .executableTarget(name: "SimpleTile", dependencies: ["SimpleTileCore"]),
        .testTarget(
            name: "SimpleTileCoreTests",
            dependencies: ["SimpleTileCore"],
            swiftSettings: testSettings
        ),
    ]
)
