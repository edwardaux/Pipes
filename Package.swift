// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pipes",
    products: [
        .library(name: "Pipes", targets: [ "Pipes" ]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Pipes", dependencies: []),
        .testTarget(name: "PipesTests", dependencies: [ "Pipes" ]),
    ]
)
