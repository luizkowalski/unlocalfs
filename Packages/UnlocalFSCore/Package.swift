// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UnlocalFSCore",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "UnlocalFSDomain", targets: ["UnlocalFSDomain"]),
        .library(name: "UnlocalFSInfrastructure", targets: ["UnlocalFSInfrastructure"]),
        .library(name: "UnlocalFSPresentation", targets: ["UnlocalFSPresentation"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-subprocess", from: "1.0.0")
    ],
    targets: [
        .target(name: "UnlocalFSDomain", resources: [.process("Resources")]),
        .target(name: "UnlocalFSInfrastructure", dependencies: [
            "UnlocalFSDomain",
            .product(name: "Subprocess", package: "swift-subprocess")
        ], resources: [.process("Resources")]),
        .target(name: "UnlocalFSPresentation", dependencies: ["UnlocalFSDomain"], resources: [.process("Resources")]),
        .target(name: "UnlocalFSTestSupport", dependencies: ["UnlocalFSDomain", "UnlocalFSInfrastructure"], path: "Tests/UnlocalFSTestSupport"),
        .testTarget(name: "UnlocalFSDomainTests", dependencies: ["UnlocalFSDomain", "UnlocalFSTestSupport"]),
        .testTarget(name: "UnlocalFSCoreTests", dependencies: [
            "UnlocalFSDomain", "UnlocalFSInfrastructure", "UnlocalFSPresentation", "UnlocalFSTestSupport"
        ]),
        .testTarget(name: "UnlocalFSPresentationTests", dependencies: [
            "UnlocalFSPresentation", "UnlocalFSDomain", "UnlocalFSInfrastructure", "UnlocalFSTestSupport"
        ])
    ]
)
