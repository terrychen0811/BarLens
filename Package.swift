// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BarChaneg",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BarChaneg", targets: ["BarChaneg"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BarChaneg",
            path: "Sources/BarChaneg"
        )
    ]
)
