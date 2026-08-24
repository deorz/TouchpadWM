// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TouchpadWM",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "TouchpadWM", targets: ["TouchpadWM"]),
        .executable(name: "TouchpadWMSpike", targets: ["TouchpadWMSpike"])
    ],
    dependencies: [
        .package(url: "https://github.com/Kyome22/OpenMultitouchSupport.git", from: "4.0.0"),
        .package(url: "https://github.com/swiftlang/swift-format.git", exact: "603.0.0")
    ],
    targets: [
        .executableTarget(name: "TouchpadWM"),
        .testTarget(name: "TouchpadWMTests", dependencies: ["TouchpadWM"]),
        .executableTarget(
            name: "TouchpadWMSpike",
            dependencies: [.product(name: "OpenMultitouchSupport", package: "OpenMultitouchSupport")]
        ),
        .testTarget(name: "TouchpadWMSpikeTests", dependencies: ["TouchpadWMSpike"])
    ]
)
