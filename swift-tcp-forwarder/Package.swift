// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TCPForwarder",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TCPForwarder",
            targets: ["TCPForwarder"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", branch: "master"),
        .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TCPForwarder",
            dependencies: ["CocoaAsyncSocket"]
        ),
        .testTarget(
            name: "swift-tcp-forwarderTests",
            dependencies: ["TCPForwarder"]
        ),
        .executableTarget(
            name: "EchoServer",
            dependencies: [
                "CocoaAsyncSocket",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/echo-server-cli"
        ),
    ]
)
