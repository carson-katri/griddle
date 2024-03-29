// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Griddle",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(name: "Griddle", targets: ["Griddle"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/TokamakUI/Tokamak", branch: "fiber/view-support"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "Griddle",
            dependencies: [
                .product(name: "TokamakShim", package: "Tokamak"),
            ],
            resources: [
                .copy("checkmark.svg"),
                .copy("xmark.svg"),
                .copy("favicon.ico"),
            ],
            linkerSettings: [
                .unsafeFlags(
                  ["-Xlinker", "--stack-first", "-Xlinker", "-z", "-Xlinker", "stack-size=16777216"],
                  .when(platforms: [.wasi])
                ),
            ]
        ),
        .testTarget(
            name: "GriddleTests",
            dependencies: ["Griddle"]),
    ]
)
