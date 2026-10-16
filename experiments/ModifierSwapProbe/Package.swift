// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ModifierSwapProbe",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "ModifierSwapProbe", targets: ["ModifierSwapProbe"])],
    targets: [
        .target(name: "ModifierSwapCore"),
        .executableTarget(name: "ModifierSwapProbe", dependencies: ["ModifierSwapCore"]),
        .executableTarget(name: "ModifierSwapChecks", dependencies: ["ModifierSwapCore"],
                          path: "Tests/ModifierSwapCoreTests"),
    ]
)
