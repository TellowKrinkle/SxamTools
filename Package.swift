// swift-tools-version:5.0

import PackageDescription

let package = Package(
	name: "SxamTools",
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
		.package(url: "https://github.com/tellowkrinkle/SwiftBinaryReader.git", from: "0.1.4"),
	],
	targets: [
		.target(
			name: "SxamExtract",
			dependencies: ["ArgumentParser", "BinaryReader"]
		),
	]
)
