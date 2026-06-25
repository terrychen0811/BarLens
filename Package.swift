// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BarLens",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BarLens", targets: ["BarLens"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BarLens",
            path: "Sources/BarLens"
        )
    ]
)
