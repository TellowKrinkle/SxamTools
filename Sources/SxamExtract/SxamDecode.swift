import ArgumentParser
import BinaryReader
import Foundation

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
