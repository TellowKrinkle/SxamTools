func decrypt(_ src: ArraySlice<UInt8>, key: UInt64 = 0x215901a9b1a1c553) -> Array<UInt8> {
	return [UInt8](unsafeUninitializedCapacity: src.count) { (buf, count) in
		var x: UInt8 = 0
		var srcprev = UInt8(truncatingIfNeeded: key)
		var i = 0
		for srcbyte in src {
			let dstbyte = (srcbyte &- x) ^ srcprev
			buf[i] = dstbyte
			i += 1
			x = x &+ UInt8(truncatingIfNeeded: key &>> ((i % 8) * 8))
			srcprev = srcbyte
		}
		count = src.count
	}
}

func fnv(_ src: ArraySlice<UInt8>) -> UInt64 {
	var hash: UInt64 = 0xcbf29ce484222325
	for byte in src {
		hash = (hash &* 0x100000001b3) ^ UInt64(byte)
	}
	return hash
}
