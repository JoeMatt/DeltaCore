// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeltaCore",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "DeltaCore", targets: ["DeltaCore", "DeltaTypes"]),
    ],
    dependencies: [
        .package(name: "ZIPFoundation", url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMinor(from: "0.9.16"))
    ],
    targets: [
        .target(
            name: "DeltaTypes",
            publicHeadersPath: "include"
        ),
        .target(
            name: "DeltaCore",
            dependencies: ["DeltaTypes", "ZIPFoundation"],
            resources: [
                .copy("Resources/KeyboardGameController.deltamapping"),
                .copy("Resources/MFiGameController.deltamapping"),
            ],
            publicHeadersPath: "include",
            cSettings: [
                .define("GLES_SILENCE_DEPRECATION"),
                .define("CI_SILENCE_GL_DEPRECATION")
            ],
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
                .linkedFramework("AVFoundation", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
                .linkedFramework("GLKit", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
                .linkedFramework("WatchKit", .when(platforms: [.watchOS]))
            ]
        ),
    ]
)
