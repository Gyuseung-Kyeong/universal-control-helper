// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "UniversalControlHelper",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "UniversalControlCore", targets: ["UniversalControlCore"]),
        .executable(name: "UniversalControlHelper", targets: ["UniversalControlHelper"]),
    ],
    targets: [
        .target(name: "UniversalControlCore"),
        .executableTarget(
            name: "UniversalControlHelper",
            dependencies: [
                "UniversalControlCore",
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedFramework("IOKit"),
                .linkedFramework("Network"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(name: "UniversalControlCoreTests", dependencies: ["UniversalControlCore"]),
        .testTarget(name: "UniversalControlHelperTests", dependencies: ["UniversalControlHelper"]),
    ]
)
