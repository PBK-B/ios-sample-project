// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KSCrashInstallationFile",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "KSCrashInstallationFile",
            targets: ["KSCrashInstallationFile"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "KSCrash", url: "https://github.com/kstenerud/KSCrash.git", from: "1.17.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "KSCrashInstallationFile",
            dependencies: ["KSCrash"]
        ),
        .testTarget(
            name: "KSCrashInstallationFileTests",
            dependencies: ["KSCrashInstallationFile", "KSCrash"]
        ),
    ]
)
