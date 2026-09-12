import AppKit
import ImageIO

// Run from the repository root after the full-bleed cream master is installed.
// iOS applies its own icon mask: never add a corner radius or inset here.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let masterPath = "Design/HaneenBrand/AppIcon-Cream.png"

func failure(_ message: String) -> NSError {
    NSError(domain: "HaneenIconPackaging", code: 1,
            userInfo: [NSLocalizedDescriptionKey: message])
}

guard let source = CGImageSourceCreateWithURL(root.appendingPathComponent(masterPath) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    throw failure("Cannot load \(masterPath).")
}
guard image.width == image.height, image.width >= 1024 else {
    throw failure("The icon master must be square and at least 1024 × 1024 pixels.")
}

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
// A PNG can contain an alpha channel while every pixel is opaque. Check the
// actual pixels, so transparent corners cannot silently acquire another colour.
var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
let isOpaque = pixels.withUnsafeMutableBytes { buffer -> Bool in
    guard let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                                  bitsPerComponent: 8, bytesPerRow: image.width * 4, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let bytes = buffer.bindMemory(to: UInt8.self)
    return stride(from: 3, to: bytes.count, by: 4).allSatisfy { bytes[$0] == 255 }
}
guard isOpaque else {
    throw failure("The cream master contains transparency. Supply an opaque, full-bleed square before packaging.")
}

func icon(_ size: Int, _ path: String) throws {
    guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                  bytesPerRow: size * 4, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw failure("Cannot create \(size)px icon context.")
    }
    // User-selected cream swatch: #FCF3E3, behind the full-bleed master.
    context.setFillColor(CGColor(red: 252.0 / 255, green: 243.0 / 255, blue: 227.0 / 255, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
    guard let outputImage = context.makeImage(),
          let output = CGImageDestinationCreateWithURL(root.appendingPathComponent(path) as CFURL,
                                                       "public.png" as CFString, 1, nil) else {
        throw failure("Cannot create \(path).")
    }
    CGImageDestinationAddImage(output, outputImage, nil)
    guard CGImageDestinationFinalize(output) else { throw failure("Cannot export \(path).") }
}

let directory = "Sakina/Assets.xcassets/AppIcon.appiconset/"
let data = try Data(contentsOf: root.appendingPathComponent(directory + "Contents.json"))
guard let manifest = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let entries = manifest["images"] as? [[String: Any]] else {
    throw failure("Invalid app icon catalog manifest.")
}
for entry in entries {
    guard let size = entry["size"] as? String,
          let points = Double(size.components(separatedBy: "x")[0]),
          let scale = entry["scale"] as? String, let multiplier = Double(scale.dropLast()),
          let filename = entry["filename"] as? String else {
        throw failure("An app icon catalog entry is missing its size, scale or filename.")
    }
    try icon(Int(points * multiplier), directory + filename)
}
try icon(120, "Sakina/Resources/AppIcon60x60@2x.png")
try icon(180, "Sakina/Resources/AppIcon60x60@3x.png")
try icon(152, "Sakina/Resources/AppIcon76x76@2x.png")
print("Packaged \(entries.count) catalog icons and 3 legacy resources from \(masterPath).")
