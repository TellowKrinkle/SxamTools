// swift-tools-version:5.2

import PackageDescription

let package = Package(
	name: "SxamTools",
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
		.package(url: "https://github.com/tellowkrinkle/SwiftBinaryReader.git", .upToNextMinor(from: "0.2.3")),
	],
	targets: [
		.target(
			name: "SxamExtract",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "BinaryReader", package: "SwiftBinaryReader"),
			]
		),
	]
)
