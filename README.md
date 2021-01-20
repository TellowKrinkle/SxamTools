# Sxam Tools

Tools for the files used by [Higurashi Mei](https://higurashi-mei.com)

# File Format Documentation
## list.bin

List files are encrypted using the algorithm shown in [Crypto.swift](Sources/SxamExtract/Crypto.swift) with the key 0x215901a9b1a1c553.  `hash.dat` contains the fnv hash of the decrypted data.

### Main File

|Name     |Type            |
|:--------|:---------------|
|NumGroups|UInt32          |
|Groups   |Group[NumGroups]|
|NumItems |UInt32          |
|Items    |Item[NumItems]  |

### Group

|Name|Type   |
|:---|:------|
|Size|UInt32 |
|Name|CString|

### Item
|Name     |Type   |Notes|
|:--------|:------|:----|
|Name     |CString|     |
|Group    |UInt16 |Offset into main file's Groups array|
|ID       |UInt32 |     |
|Pos      |UInt64 |Position in data.bin|
|Size     |UInt32 |Length in data.bin|
|Hash     |UInt64 |FNV hash of decrypted data, and also the encryption key used|

## Sx1.05 Image Atlas
These files are stored with the extension `.bin` and have `Sx1.05` as their file magic

### Main File

|Name       |Type                |Notes|
|:----------|:-------------------|:----|
|Magic      |CString             |Should be `Sx1.05`|
|Type       |UInt8               |Image encoding, 1 => ARGB32, 2 => PVRTC RGB4, 3 => ETC RGB4, 4 => DXT1, 5 => DXT5|
|           |UInt64              |Purpose unknown|
|Width      |UInt16              |      |
|Height     |UInt16              |      |
|ImageSize  |UInt32              |Decompressed size of Image|
|Image      |Compressed Data     |See below, keep reading until the decompressed data is ImageSize bytes|
|ImageASize |UInt32              |Decompressed size of ImageA, only present for Types 2 and 3|
|ImageA     |Compressed Data     |Same as Image, only present for types 2 and 3|
|NumSections|UInt32              |      |
|Sections   |Section[NumSections]|      |

For files with an ImageA (types 2 and 3), Image contains the final image's red and green channels, while ImageA contains its blue and alpha, therefore to create the final image, use the following mapping:
- Final.R = Image.R
- Final.G = Image.G
- Final.B = ImageA.R
- Final.A = ImageA.B

### Data Compression
To decompress data:
1. Read an Int16
2. If the value from ① is greater than or equal to zero, read that number of bytes into the output buffer and go to ①
3. Read a UInt16
4. Copy ③ bytes starting at ① bytes away from the end of the output buffer and go to ①


### Section
|Name     |Type   |
|:--------|:------|
|Name     |CString|
|Width    |UInt16 |
|Height   |UInt16 |
|x0       |Float32|
|y0       |Float32|
|x1       |Float32|
|y1       |Float32|
|u0       |Float32|
|v0       |Float32|
|u1       |Float32|
|v1       |Float32|

x and y seem to always be 0 and 1, they probably map how the image should be drawn onto an image of size Width x Height

u and v are the texture coordinates from the main file's image texture
