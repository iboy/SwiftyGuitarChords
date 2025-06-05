// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyGuitarChords",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SwiftyChords",
            targets: ["SwiftyChords"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .target(
            name: "SwiftyChords",
            dependencies: [],
            resources: [
                    .copy("Resources/GuitarChords.json")  // Copy the JSON file as a resource
                ],
            swiftSettings: [
                // Modern syntax for Swift 5.8+
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("ForwardTrailingClosures")
            ]
        ),
        .testTarget(
            name: "SwiftyChordsTests",
            dependencies: ["SwiftyChords"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("ForwardTrailingClosures")
            ]
        ),
    ]
)
