// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Thrift",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Thrift",
            targets: ["Thrift"]),
        .library(
            name: "ThriftStatic",
            type: .static,
            targets: ["Thrift"]),
        .library(
            name: "ThriftDynamic",
            type: .dynamic,
            targets: ["Thrift"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Thrift",
            dependencies: [],
            path: "Sources",
            exclude: ["Info.plist"]),
    ]
)
