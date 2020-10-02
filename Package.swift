// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "RuntimeIssues",
    platforms: [.iOS(.v12), .watchOS(.v5), .tvOS(.v12), .macOS(.v10_14)],
    products: [
        .library(name: "RuntimeIssues", targets: ["RuntimeIssues"]),
    ],
    targets: [
        .target(name: "RuntimeIssues"),
        .testTarget(name: "RuntimeIssuesTests", dependencies: ["RuntimeIssues"]),
    ]
)
