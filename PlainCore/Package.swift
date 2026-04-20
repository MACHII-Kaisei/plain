// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PlainCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PlainCore", targets: ["PlainCore"])
    ],
    targets: [
        .target(name: "PlainCore", path: "Sources/PlainCore"),
        .testTarget(name: "PlainCoreTests", dependencies: ["PlainCore"], path: "Tests/PlainCoreTests")
    ]
)
