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
