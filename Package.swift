// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DisplayPresets",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DisplayPresets",
            path: "Sources/DisplayPresets",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
    ]
)
