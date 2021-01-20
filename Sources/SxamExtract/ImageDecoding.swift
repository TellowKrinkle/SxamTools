import SwiftLodePNG
import SwiftUnityTexture2DDecoder


extension Sx1_05 {
	func decode() -> RGBA8Image? {
		var decodedImageData: [UInt8]
		var decodedImageData2: [UInt8] = []
		switch type {
		case 1:
			decodedImageData = image
		case 2:
			guard let t0 = decodeUnityTexture2D(image,  format: .pvrtc_rgb4, width: Int(width), height: Int(height)),
			      let t1 = decodeUnityTexture2D(imageA, format: .pvrtc_rgb4, width: Int(width), height: Int(height))
			else { return nil }
			decodedImageData = t0
			decodedImageData2 = t1
		case 3:
			guard let t0 = decodeUnityTexture2D(image,  format: .etc_rgb4, width: Int(width), height: Int(height)),
			      let t1 = decodeUnityTexture2D(imageA, format: .etc_rgb4, width: Int(width), height: Int(height))
			else { return nil }
			decodedImageData = t0
			decodedImageData2 = t1
		case 4:
			guard let t = decodeUnityTexture2D(image, format: .dxt1, width: Int(width), height: Int(height)) else { return nil }
			decodedImageData = t
		case 5:
			guard let t = decodeUnityTexture2D(image, format: .dxt5, width: Int(width), height: Int(height)) else { return nil }
			decodedImageData = t
		default:
			return nil
		}
		var out = RGBA8Image(width: Int(width), height: Int(height), data: decodedImageData)
		out.withMutableBuffer { out in
			// Output is BGRA, we want RGBA
			if !decodedImageData2.isEmpty {
				var out2 = RGBA8Image(width: Int(width), height: Int(height), data: decodedImageData2)
				out2.withMutableBuffer { out2 in
					for index in out.indices {
						out[index].r = out2[index].b
						out[index].a = out2[index].g
					}
				}
			}
			for index in out.indices {
				let tmp = out[index].r
				out[index].r = out[index].b
				out[index].b = tmp
			}
		}
		return out
	}
}
