// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-binary-cursor",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Binary Cursor",
            targets: ["Binary Cursor"]
        ),
        .library(
            name: "Binary Cursor Test Support",
            targets: ["Binary Cursor Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-binary.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-span.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-byte.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Binary Cursor",
            dependencies: [
                .product(name: "Binary Primitive", package: "swift-binary"),
                .product(name: "Index", package: "swift-index"),
                .product(name: "Span Protocol", package: "swift-span"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),
        .target(
            name: "Binary Cursor Test Support",
            dependencies: [
                "Binary Cursor",
                .product(
                    name: "Binary Test Support",
                    package: "swift-binary"
                ),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Binary Cursor Tests",
            dependencies: [
                "Binary Cursor",
                "Binary Cursor Test Support",
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
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
