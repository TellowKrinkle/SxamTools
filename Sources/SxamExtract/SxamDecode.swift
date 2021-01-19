import ArgumentParser
import BinaryReader
import Foundation
import SwiftUnityTexture2DDecoder
import SwiftLodePNG

extension Optional {
	func unwrapOrThrow(_ error: @autoclosure () -> Error) throws -> Wrapped {
		if let out = self { return out } else { throw error() }
	}
}

extension LodePNGImage {
	mutating func flipVertically() {
		for y in 0..<(height/2) {
			for x in 0..<width {
				let tmp = self[x: x, y: y]
				self[x: x, y: y] = self[x: x, y: height - y - 1]
				self[x: x, y: height - y - 1] = tmp
			}
		}
	}

	func flippedVertically() -> LodePNGImage {
		var out = self
		out.flipVertically()
		return out
	}

	func subimage(horizontal: Range<Int>, vertical: Range<Int>) -> LodePNGImage {
		var new = LodePNGImage(width: horizontal.count, height: vertical.count)
		var i = 0
		for y in vertical {
			for x in horizontal {
				new[i] = self[x: x, y: y]
				i += 1
			}
		}
		return new
	}
}

struct SxamDecode: ParsableCommand {
	static var configuration = CommandConfiguration(
		commandName: "decode",
		abstract: "Decode .bin files with headers in the form Sx#.##\nCurrently supports Sx1.05"
	)

	enum Error: LocalizedError {
		case unknownMagic(String)
		case failedToDecodeImage

		var errorDescription: String? {
			switch self {
			case .unknownMagic(let magic):
				return "Unrecognized file magic: \(magic)"
			case .failedToDecodeImage:
				return "Failed to decode image"
			}
		}
	}

	@Argument(help: "The .bin file", completion: .file(extensions: [".bin"]))
	var path: String

	@Option(help: "Output directory", completion: .directory)
	var out: String?

	func run() throws {
		var reader = try BufferedReader(FileReader(path: path))
		let basename = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
		let outBase = out.map(URL.init(fileURLWithPath:))
		switch try SxFile(reader: &reader) {
		case .unknown(magic: let magic):
			throw Error.unknownMagic(magic)
		case .v1_05(let file):
			if let outBase = outBase {
				if let ktxType = file.ktxType {
					var output = ArrayReader()
					try writeKTX(file.image, type: ktxType, width: UInt32(file.width), height: UInt32(file.height), to: &output)
					try Data(output.currentArray).write(to: outBase.appendingPathComponent("\(basename).ktx"))
					if (!file.imageA.isEmpty) {
						output = ArrayReader()
						try writeKTX(file.imageA, type: ktxType, width: UInt32(file.width), height: UInt32(file.height), to: &output)
						try Data(output.currentArray).write(to: outBase.appendingPathComponent("\(basename)_a.ktx"))
					}
				}
				try JSONEncoder().encode(file.sections).write(to: outBase.appendingPathComponent("\(basename).json"))
				guard let decoded = file.decode() else { throw Error.failedToDecodeImage }
				try decoded.flippedVertically().encode().write(to: outBase.appendingPathComponent("\(basename).png"))
				for section in file.sections {
					let x0 = Int((section.texturePosition.x0 * Float(file.width)).rounded(.towardZero))
					let y0 = Int((section.texturePosition.y0 * Float(file.height)).rounded(.towardZero))
					let x1 = Int((section.texturePosition.x1 * Float(file.width)).rounded(.awayFromZero))
					let y1 = Int((section.texturePosition.y1 * Float(file.height)).rounded(.awayFromZero))
					var subimage = decoded.subimage(horizontal: x0..<x1 as Range<Int>, vertical: y0..<y1 as Range<Int>)
					subimage.flipVertically()
					var filename = "\(basename)_\(section.name).png"
					if basename == section.name {
						filename = "\(basename).png"
					}
					try subimage.encode().write(to: outBase.appendingPathComponent(filename))
				}
			} else {
				print("Found valid Sx1.05 file \(file.width)x\(file.height) image with \(file.sections.count) sections")
				print("Specify --out to dump")
			}
		}
	}
}
