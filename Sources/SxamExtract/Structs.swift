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
