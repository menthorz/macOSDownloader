// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "macOS-Version-Manager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "macOS-Version-Manager",
            targets: ["macOS-Version-Manager"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "macOS-Version-Manager",
            dependencies: [],
            resources: [
                .process("Assets")
            ]
        )
    ]
)
