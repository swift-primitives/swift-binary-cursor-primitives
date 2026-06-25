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
        .package(url: "https://github.com/swift-primitives/swift-binary-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-span-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Binary Cursor Primitives",
            dependencies: [
                .product(name: "Binary Primitive", package: "swift-binary-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
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
