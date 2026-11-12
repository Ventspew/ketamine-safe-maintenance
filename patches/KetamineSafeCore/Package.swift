// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KetamineSafeCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "KetamineSafeCore", targets: ["KetamineSafeCore"])
    ],
    targets: [
        .target(name: "KetamineSafeCore"),
        .testTarget(
            name: "KetamineSafeCoreTests",
            dependencies: ["KetamineSafeCore"]
        )
    ]
)
