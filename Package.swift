// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LanguageClient",
    platforms: [
      .macOS(.v10_13)
    ],
    products: [
      .library(name: "LanguageClient",
               targets: ["LanguageClient"])
    ],
    dependencies: [
      .package(url: "https://github.com/mxcl/PromiseKit", from: "6.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "LanguageClient",
            dependencies: ["PromiseKit"]),
        .testTarget(
            name: "LanguageClientTests",
            dependencies: ["LanguageClient"]),
    ]
)
