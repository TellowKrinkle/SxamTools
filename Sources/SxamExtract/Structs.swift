import BinaryReader

struct GroupData {
	var size: UInt32
	var name: String
}

struct Item {
	var name: String
	var grp:  UInt16
	var id:   UInt32
	var pos:  UInt64
	var size: UInt32
	var hash: UInt64
}

struct ListFile {
	var groups: [GroupData]
	var items: [Item]
}

extension ListFile {
	init<Reader: BinaryReader>(reader: inout Reader) throws {
		groups = try (0..<reader.forceReadLE(UInt32.self)).map { _ in
			return GroupData(
				size: try reader.forceReadLE(),
				name: try reader.readNullTerminatedString()
			)
		}
		items = try (0..<reader.forceReadLE(UInt32.self)).map { _ in
			return Item(
				name: try reader.readNullTerminatedString(),
				grp:  try reader.forceReadLE(),
				id:   try reader.forceReadLE(),
				pos:  try reader.forceReadLE(),
				size: try reader.forceReadLE(),
				hash: try reader.forceReadLE()
			)
		}
	}
}

struct Rectangle: Codable {
	var x0: Float
	var y0: Float
	var x1: Float
	var y1: Float
}

extension Rectangle {
	init<Reader: BinaryReader>(reader: inout Reader) throws {
		x0 = try reader.forceReadLE()
		y0 = try reader.forceReadLE()
		x1 = try reader.forceReadLE()
		y1 = try reader.forceReadLE()
	}
}

struct Sx1_05 {
	struct Section: Codable {
		var name: String
		var width: Float
		var height: Float
		var position: Rectangle
		var texturePosition: Rectangle
	}

	var type: UInt8 // Mapping to Unity Texture2D: 1 => 5 (ARGB32), 2 => 32 (PVRTC RGB4), 3 => 34 (ETC RGB4), 4 => 10 (DXT1), 5 => 12 (DXT5)
	var unknown: [UInt8]
	var width: UInt16
	var height: UInt16
	var image: [UInt8]
	var imageA: [UInt8]
	var sections: [Section]

	var ktxType: KTXType? {
		switch type {
		case 3: return .etc_rgb4
		default: return nil
		}
	}
}

extension Sx1_05 {
	static func loadTexture<Reader: BinaryReader>(reader: inout Reader) throws -> [UInt8] {
		let size = Int(try reader.forceReadLE(UInt32.self))
		var out: [UInt8] = []
		out.reserveCapacity(size)
		while out.count < size {
			let val = Int(try reader.forceReadLE(Int16.self))
			if val < 0 {
				let len = try reader.forceReadLE(UInt16.self)
				for _ in 0..<len {
					out.append(out[out.count + val])
				}
			} else {
				let cur = out.count
				out.append(contentsOf: repeatElement(0, count: val))
				try out.withUnsafeMutableBytes { ptr in
					let target = UnsafeMutableRawBufferPointer(rebasing: ptr[cur...])
					try reader.forceRead(into: target)
				}
			}
		}
		return out
	}

	init<Reader: BinaryReader>(reader: inout Reader) throws {
		let type = try reader.forceRead(UInt8.self)
		self.type = type
		unknown = try reader.forceReadBytes(8)
		width = try reader.forceReadLE()
		height = try reader.forceReadLE()
		image = try Sx1_05.loadTexture(reader: &reader)
		let hasImageA = type == 2 || type == 3
		imageA = hasImageA ? try Sx1_05.loadTexture(reader: &reader) : []
		let count = try reader.forceReadLE(UInt32.self)
		sections = try (0..<count).map { _ in try .init(reader: &reader) }
	}
}

extension Sx1_05.Section {
	init<Reader: BinaryReader>(reader: inout Reader) throws {
		name = try reader.readNullTerminatedString()
		width = try reader.forceReadLE()
		height = try reader.forceReadLE()
		position = try .init(reader: &reader)
		texturePosition = try .init(reader: &reader)
	}
}

enum SxFile {
	indirect case v1_05(Sx1_05)
	case unknown(magic: String)
}

extension SxFile {
	init<Reader: BinaryReader>(reader: inout Reader) throws {
		let magic = try reader.readNullTerminatedString()
		switch magic {
		case "Sx1.05":
			self = .v1_05(try .init(reader: &reader))
		default:
			self = .unknown(magic: magic)
		}
	}
}
