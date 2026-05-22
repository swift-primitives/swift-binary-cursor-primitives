// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-binary-cursor-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Binary Cursor Primitives",
            targets: ["Binary Cursor Primitives"]
        ),
        .library(
            name: "Binary Cursor Primitives Test Support",
            targets: ["Binary Cursor Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-binary-primitives"),
        .package(path: "../swift-cursor-primitives"),
        .package(path: "../swift-memory-cursor-primitives"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-memory-primitives"),
    ],
    targets: [
        .target(
            name: "Binary Cursor Primitives",
            dependencies: [
                .product(name: "Binary Primitive", package: "swift-binary-primitives"),
                .product(name: "Binary Error Primitives", package: "swift-binary-primitives"),
                .product(name: "Cursor Primitives", package: "swift-cursor-primitives"),
                .product(name: "Memory Cursor Primitives", package: "swift-memory-cursor-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Contiguous Primitives", package: "swift-memory-primitives"),
            ]
        ),
        .target(
            name: "Binary Cursor Primitives Test Support",
            dependencies: [
                "Binary Cursor Primitives",
                .product(name: "Binary Primitives Test Support", package: "swift-binary-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Binary Cursor Primitives Tests",
            dependencies: [
                "Binary Cursor Primitives",
                "Binary Cursor Primitives Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
