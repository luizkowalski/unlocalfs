// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UnlocalFSCore",
    platforms: [.macOS(.v15)],
    products: [.library(name: "UnlocalFSCore", targets: ["UnlocalFSCore"])],
    dependencies: [.package(url: "https://github.com/swiftlang/swift-subprocess", from: "1.0.0")],
    targets: [
        .target(name: "UnlocalFSCore", dependencies: [.product(name: "Subprocess", package: "swift-subprocess")]),
        .testTarget(name: "UnlocalFSCoreTests", dependencies: ["UnlocalFSCore"])
    ]
)
