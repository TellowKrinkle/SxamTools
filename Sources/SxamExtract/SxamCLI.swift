import ArgumentParser
import BinaryReader
import Foundation

struct SxamExtract: ParsableCommand {
	static var configuration = CommandConfiguration(
		commandName: "extract",
		abstract: "Extract files from a list.bin + data.bin archive"
	)

	enum Error: Swift.Error {
		case hashMismatch(file: String, expected: UInt64, actual: UInt64)
	}

	@Option(help: "The list.bin file", completion: .file(extensions: [".bin"]))
	var list: String

	@Option(help: "The data.bin file", completion: .file(extensions: [".bin"]))
	var data: String

	@Option(help: "Output directory")
	var out: String?

	@Option(help: "The hash.bin file", completion: .file(extensions: [".bin"]))
	var hash: String?

	func run() throws {
		var listFile = try FileReader(path: self.list)
		let listData = decrypt(try listFile.readAll()[...])

		if let hashPath = self.hash {
			// If the user specified a hash file, use it to verify the list was correctly decrypted
			var hashFile = try FileReader(path: hashPath)
			let expected = try hashFile.forceReadLE(UInt64.self)
			let actual = fnv(listData[...])
			if expected != actual {
				throw Error.hashMismatch(file: self.list, expected: expected, actual: actual)
			}
		}

		var listReader = ArrayReader(listData)
		let list = try ListFile(reader: &listReader)

		guard let out = out else {
			// If the user doesn't specify an output file, print the contents of the list file and exit
			print("Groups")
			for group in list.groups { print("\t\(group)")}
			print("Items")
			for item in list.items { print("\t\(item)") }
			let remaining = try listReader.readAll()
			if !remaining.allSatisfy({ $0 == 0 }) {
				print("\(remaining.count) unused bytes")
			}
			print("\nSpecify --out to dump")
			return
		}

		var data = try FileReader(path: self.data)
		let base = URL(fileURLWithPath: out)
		for item in list.items {
			let group = list.groups[Int(item.grp)]
			let url = base
				.appendingPathComponent(group.name)
				.appendingPathComponent(item.name)
				.appendingPathExtension("unity3d")
			try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
			try data.seek(to: Int(item.pos))
			let contents = try data.forceReadBytes(Int(item.size))
			let dec = decrypt(contents[...], key: item.hash)
			let actual = fnv(dec[...])
			if actual != item.hash {
				throw Error.hashMismatch(file: url.path, expected: item.hash, actual: actual)
			}
			try Data(dec).write(to: url)
		}
	}
}

struct SxamDecode: ParsableCommand {
	static var configuration = CommandConfiguration(
		commandName: "decode",
		abstract: "Decode .bin files with headers in the form Sx#.##\nCurrently supports Sx1.05"
	)

	enum Error: LocalizedError {
		case unknownMagic(String)

		var errorDescription: String? {
			switch self {
			case .unknownMagic(let magic):
				return "Unrecognized file magic: \(magic)"
			}
		}
	}

	@Argument(help: "The .bin file", completion: .file(extensions: [".bin"]))
	var path: String

	@Option(help: "Output directory", completion: .directory)
	var out: String?

	func run() throws {
		var reader = try BufferedReader(FileReader(path: path))
		let outBase = out.map { out -> URL in
			let pathURL = URL(fileURLWithPath: path)
			let outURL = URL(fileURLWithPath: out)
			return outURL.appendingPathComponent(pathURL.deletingPathExtension().lastPathComponent)
		}
		switch try SxFile(reader: &reader) {
		case .unknown(magic: let magic):
			throw Error.unknownMagic(magic)
		case .v1_05(let file):
			if let outBase = outBase {
				if let ktxType = file.ktxType {
					let outURL = outBase.appendingPathExtension("ktx")
					var output = ArrayReader()
					try writeKTX(file.image, type: ktxType, width: UInt32(file.width), height: UInt32(file.height), to: &output)
					try Data(output.currentArray).write(to: outURL)
					if (!file.imageA.isEmpty) {
						let alphaURL = outBase.appendingPathExtension("a.ktx")
						output = ArrayReader()
						try writeKTX(file.imageA, type: ktxType, width: UInt32(file.width), height: UInt32(file.height), to: &output)
						try Data(output.currentArray).write(to: alphaURL)
					}
				} else {
					print("Unsupported image type \(file.type), not dumping")
				}
				let jsonURL = outBase.appendingPathExtension("json")
				try JSONEncoder().encode(file.sections).write(to: jsonURL)
			} else {
				print("Found valid Sx1.05 file \(file.width)x\(file.height) image with \(file.sections.count) sections")
				print("Specify --out to dump")
			}
		}
	}
}

struct SxamCLI: ParsableCommand {
	static var configuration = CommandConfiguration(
		commandName: CommandLine.arguments[0],
		abstract: "A tool for reading Higurashi Mei's resource files",
		subcommands: [SxamExtract.self, SxamDecode.self]
	)
}
