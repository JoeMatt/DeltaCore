// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeltaCore",
	defaultLocalization: "en",
    platforms: [
        .iOS(.v12),
        .macOS(.v12),
        .tvOS(.v12),
        .macCatalyst(.v13)
    ],
    products: [
        .library(name: "DeltaCore",
                 targets: ["DeltaCore"]),
        .library(name: "DeltaCoreStatic",
                 type: .static,
                 targets: ["DeltaCore"]),
        .library(name: "DeltaCoreDynamic",
                 type: .dynamic,
                 targets: ["DeltaCore"]),

        /// DeltaTypes (unused ATM)
        .library(name: "DeltaTypes",
                 targets: ["DeltaTypes"]),
        .library(name: "DeltaTypesStatic",
                 type: .static,
                 targets: ["DeltaTypes"]),
        .library(name: "DeltaTypesDynamic",
                 type: .dynamic,
                 targets: ["DeltaTypes"]),

    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: .init(0, 9, 16)),
    ],
    targets: [
        .target(
            name: "DeltaTypes",
            publicHeadersPath: "include",
			cSettings: [
				.define("GL_SILENCE_DEPRECATION"),
				.define("GLES_SILENCE_DEPRECATION"),
				.define("CI_SILENCE_GL_DEPRECATION"),
				.headerSearchPath("../DeltaCore/include")
			],
			swiftSettings: [
				.define("GL_SILENCE_DEPRECATION"),
				.define("GLES_SILENCE_DEPRECATION"),
				.define("CI_SILENCE_GL_DEPRECATION")
			]
        ),

        .target(
            name: "DeltaCore",
            dependencies: [
                "ZIPFoundation",
                "DeltaTypes"
            ],
            resources: [
                .copy("Resources/KeyboardGameController.deltamapping"),
                .copy("Resources/MFiGameController.deltamapping"),
            ],
//            publicHeadersPath: "include",
            cSettings: [
				.define("GL_SILENCE_DEPRECATION"),
                .define("GLES_SILENCE_DEPRECATION"),
                .define("CI_SILENCE_GL_DEPRECATION"),
                .headerSearchPath("../DeltaCore/include")
            ],
            swiftSettings: [
				.define("GL_SILENCE_DEPRECATION"),
                .define("GLES_SILENCE_DEPRECATION"),
                .define("CI_SILENCE_GL_DEPRECATION")
            ],
            linkerSettings: [
				.linkedFramework("Accelerate", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
				.linkedFramework("AVFoundation", .when(platforms: [.iOS, .tvOS, .macCatalyst, .macOS])),
				.linkedFramework("CoreImage"),
				.linkedFramework("GLKit", .when(platforms: [.iOS, .tvOS, .macOS])),
				.linkedFramework("Metal"),
				.linkedFramework("MetalKit"),
				.linkedFramework("OpenGLES", .when(platforms: [.iOS, .tvOS])),
				.linkedFramework("OpenGL", .when(platforms: [.macOS, .macCatalyst])),
				.linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS, .macCatalyst])),
				.linkedFramework("WatchKit", .when(platforms: [.watchOS]))
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
