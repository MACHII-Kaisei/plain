// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PlainCLI",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: "../PlainCore"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "plain",
            dependencies: [
                "PlainCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/PlainCLI"
        )
    ]
)
