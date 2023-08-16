// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EnalogSwift",
    platforms: [
            .macOS(.v10_13),  // macOS 10.13 (High Sierra)
            .iOS(.v11),      // iOS 11 (Equivalent to macOS 10.13 release year)
            .watchOS(.v4),   // watchOS 4 (Equivalent to macOS 10.13 release year)
            .tvOS(.v11)      // tvOS 11 (Equivalent to macOS 10.13 release year)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "EnalogSwift",
            targets: ["EnalogSwift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "EnalogSwift",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "EnalogClientTests",
            dependencies: ["EnalogSwift"]),
    ]
)
