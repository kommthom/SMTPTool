// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SMTPTool",
	platforms: [
		.macOS(.v15)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SMTPTool",
            targets: ["SMTPTool"]),
    ],
	dependencies: [
		.package(url: "https://github.com/vapor/vapor", from: "4.106.0"),
		.package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SMTPTool",
			dependencies: [
				.product(
					name: "Vapor",
					package: "vapor"
				),
				.product(
					name: "JWT",
					package: "jwt"
				)
			]
		),
        .testTarget(
            name: "SMTPToolTests",
            dependencies: ["SMTPTool"]
        ),
    ]
)
