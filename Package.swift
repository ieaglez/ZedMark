// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "JZMDReader",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "JZMDReader", targets: ["JZMDReader"])
    ],
    targets: [
        .target(
            name: "JZMDReaderCore",
            path: "Sources/JZMDReaderCore"
        ),
        .executableTarget(
            name: "JZMDReader",
            dependencies: ["JZMDReaderCore"],
            path: "Sources/JZMDReader",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("WebKit")
            ]
        ),
        .testTarget(
            name: "JZMDReaderCoreTests",
            dependencies: ["JZMDReaderCore"],
            path: "Tests/JZMDReaderCoreTests"
        )
    ]
)
