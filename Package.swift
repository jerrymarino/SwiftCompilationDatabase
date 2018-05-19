// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftCompilationDatabase",
    products: [
        .library(
            name: "LogParser",
            targets: ["SwiftCompilationDatabase"]),
    ],
    targets: [
        .target(
            name: "SwiftCompilationDatabase",
            dependencies: ["LogParser"]),
        .target(
            name: "LogParser",
            dependencies: []),

    ]
)
