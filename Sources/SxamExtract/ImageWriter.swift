import BinaryReader

enum KTXType {
	case etc_rgb4

	var ktxValues: (format: UInt32, color: UInt32) {
		switch self {
		case .etc_rgb4:
			return (0x9274, 0x1907)
		}
	}
}

func writeKTX<Writer: BinaryWriter>(_ data: [UInt8], type: KTXType, width: UInt32, height: UInt32, to writer: inout Writer) throws {
	try writer.write([0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A]) // Identifier
	try writer.writeLE(0x04030201 as UInt32) // Endianness
	for _ in 0..<3 { try writer.writeLE(0 as UInt32) } // glType, glTypeSize, glFormat
	try writer.writeLE(type.ktxValues.format) // glInternalFormat
	try writer.writeLE(type.ktxValues.color) // glBaseInternalFormat
	try writer.writeLE(width)
	try writer.writeLE(height)
	for _ in 0..<2 { try writer.writeLE(0 as UInt32) } // pixelDepth, numberOfArrayElements
	try writer.writeLE(1 as UInt32) // numberOfFaces
	try writer.writeLE(1 as UInt32) // numberOfMipmapLevels
	var str = "KTXorientation\0S=r,T=u\0" // Flip upside down
	try str.withUTF8 { ptr in
		let byteCount = (ptr.count + 3) & ~3
		try writer.writeLE(UInt32(4 + byteCount)) // bytesOfKeyValueData
		try writer.writeLE(UInt32(ptr.count)) // keyAndValueByteSize
		try writer.write(from: UnsafeRawBufferPointer(ptr)) // keyAndValue
		for _ in ptr.count..<byteCount {
			try writer.write(0 as UInt8) // padding
		}
	}
	try writer.writeLE(UInt32(data.count)) // imageSize
	try writer.write(data) // image data
}
