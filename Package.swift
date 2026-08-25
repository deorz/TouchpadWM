// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TouchpadWM",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "TouchpadWM", targets: ["TouchpadWM"]),
        .executable(name: "TouchpadWMSpike", targets: ["TouchpadWMSpikeConsole"])
    ],
    dependencies: [
        .package(url: "https://github.com/Kyome22/OpenMultitouchSupport.git", from: "4.0.0"),
        .package(url: "https://github.com/swiftlang/swift-format.git", exact: "603.0.0")
    ],
    targets: [
        .target(name: "TouchpadWMSpike", dependencies: [.product(name: "OpenMultitouchSupport", package: "OpenMultitouchSupport")]),
        .executableTarget(name: "TouchpadWM", dependencies: ["TouchpadWMSpike"]),
        .executableTarget(name: "TouchpadWMSpikeConsole", dependencies: ["TouchpadWMSpike", .product(name: "OpenMultitouchSupport", package: "OpenMultitouchSupport")]),
        .testTarget(name: "TouchpadWMTests", dependencies: ["TouchpadWM", "TouchpadWMSpike"]),
        .testTarget(name: "TouchpadWMSpikeTests", dependencies: ["TouchpadWMSpike"])
    ]
)
