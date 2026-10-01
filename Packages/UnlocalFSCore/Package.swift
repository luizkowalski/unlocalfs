// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UnlocalFSCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "UnlocalFSDomain", targets: ["UnlocalFSDomain"]),
        .library(name: "UnlocalFSInfrastructure", targets: ["UnlocalFSInfrastructure"]),
        .library(name: "UnlocalFSPresentation", targets: ["UnlocalFSPresentation"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-subprocess", from: "1.0.0"),
        .package(url: "https://github.com/joelklabo/SwiftDataValidator", from: "1.0.0")
    ],
    targets: [
        .target(name: "UnlocalFSDomain", dependencies: [
            .product(name: "SwiftDataValidator", package: "SwiftDataValidator")
        ]),
        .target(name: "UnlocalFSInfrastructure", dependencies: [
            "UnlocalFSDomain",
            .product(name: "Subprocess", package: "swift-subprocess")
        ]),
        .target(name: "UnlocalFSPresentation", dependencies: ["UnlocalFSDomain"]),
        .testTarget(name: "UnlocalFSDomainTests", dependencies: ["UnlocalFSDomain"]),
        .testTarget(name: "UnlocalFSCoreTests", dependencies: ["UnlocalFSDomain", "UnlocalFSInfrastructure", "UnlocalFSPresentation"]),
        .testTarget(name: "UnlocalFSPresentationTests", dependencies: ["UnlocalFSPresentation", "UnlocalFSDomain", "UnlocalFSInfrastructure"])
    ]
)
