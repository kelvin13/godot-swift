// swift-tools-version:999.0

import PackageDescription

let package = Package(
    name: "godot-example-package",
    products: 
    [
        .library(name: "swift-library", type: .dynamic, targets: ["GodotExample"]),
    ],
    dependencies: 
    [
        .package(url: "https://github.com/apple/swift-numerics",        .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/apple/swift-atomics.git",     .upToNextMinor(from: "0.0.1")),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.1")),
        .package(url: "https://github.com/apple/swift-package-manager", .branch("main")),
    ],
    targets: 
    [
        .plugin(name: "GenerateNativeScriptPlugin", capability: .buildTool(),
            dependencies: ["GenerateNativeScript"]),
        .executableTarget(name: "GenerateNativeScript",
            dependencies: 
            [
                .product(name: "ArgumentParser",    package: "swift-argument-parser"),
                .product(name: "SwiftPM",           package: "swift-package-manager"), 
            ],
            path: "plugin/generate-nativescript", 
            exclude: 
            [
                "fragments/",
                ".gyb/",
                "gyb/api@3.2.3.json",
                "gyb/api@3.3.0.json",
            ]),

        .target(name: "GDNativeHeaders", dependencies: [],
            path: "sources/godot-native/c", 
            exclude: 
            [
                "include/README.md", 
                "include/LICENSE.md"
            ]),
        .target(name: "GDNative", dependencies: 
            [
                .target(name: "GDNativeHeaders"),
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "Numerics", package: "swift-numerics"),
            ],
            path: "sources/godot-native/swift"), 
        
        .target(name: "GodotExample", dependencies: 
            [
                "GDNative", 
            ], 
            path: "sources/swift", 
            plugins: ["GenerateNativeScriptPlugin"])
    ]
)
