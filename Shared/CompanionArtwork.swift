import SwiftUI

/// Transparent brand artwork for in-app use; the installed app icon has its own opaque canvas.
struct YaqeenBrandIcon: View {
    var size: CGFloat = 32

    var body: some View {
        Image("YaqeenBrand")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Original pencil illustrations. Names are explicit so collection art never
/// depends on a coincidentally matching SF Symbol.
enum CompanionArtwork: String, CaseIterable {
    case morning, evening, sleep, tahajjud, salah, afterSalah
    case istighfar, praise, salawat, anytime, ummah, healing
    case quran, sunnah, names
    case angry, anxious, confident, confused, grateful, greedy, guilty, happy
    case hurt, indecisive, hypocritical, jealous, lazy, lonely, lost, overwhelmed
    case sad, scared, unloved, impatient, hopeful, grieving, breathe
    case family, shelter, work, qibla, kaaba, support
    case fajr, sunrise, dhuhr, asr, maghrib, isha
    case journal, privacy, settings, saved, appearance

    case mosque, food, verified, calculator, globe, language, reciter
    case translation, transliteration, textSize, reminder, clock, haptics, help
    case share, rating, backup, download, signout, deleteAccount
    case bug, idea, camera, social, water

    var assetName: String { "Companion-\(rawValue)" }
}

struct CompanionIllustration: View {
    let artwork: CompanionArtwork
    var size: CGFloat = 80
    var onDarkSurface = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image(uiImage: CompanionImage.image(artwork))
            .resizable()
            .scaledToFit()
            .padding(size * 0.045)
            .frame(width: size, height: size)
            .shadow(color: (colorScheme == .dark || onDarkSurface) ? Color(red: 0.89, green: 0.83, blue: 0.67).opacity(0.2) : .clear,
                    radius: 0.6)
            .accessibilityHidden(true)
    }
}

extension PrayerKind {
    var artwork: CompanionArtwork {
        switch self {
        case .fajr: return .fajr
        case .sunrise: return .sunrise
        case .dhuhr: return .dhuhr
        case .asr: return .asr
        case .maghrib: return .maghrib
        case .isha: return .isha
        }
    }
}

/// Removes only edge-connected white paper at display time. Enclosed cream fur,
/// pencil marks and source assets remain intact. Cached once per illustration.
enum CompanionImage {
    private static let cache = NSCache<NSString, UIImage>()
    static func inkMask(_ artwork: CompanionArtwork) -> UIImage {
        let key = "ink.\(artwork.assetName)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let cg = UIImage(named: artwork.assetName)?.cgImage else { return UIImage() }
        var pixels = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        guard let context = CGContext(data: &pixels, width: cg.width, height: cg.height, bitsPerComponent: 8,
                                      bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return UIImage() }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        for p in stride(from: 0, to: pixels.count, by: 4) {
            let luminance = 0.2126 * Double(pixels[p]) + 0.7152 * Double(pixels[p + 1]) + 0.0722 * Double(pixels[p + 2])
            let value = max(0, Double(pixels[p + 3]) - luminance)
            let alpha = value < 14 ? UInt8(0) : UInt8(min(255, value))
            for channel in 0..<4 { pixels[p + channel] = alpha }
        }
        guard let output = context.makeImage() else { return UIImage() }
        let image = UIImage(cgImage: output).withRenderingMode(.alwaysTemplate)
        cache.setObject(image, forKey: key)
        return image
    }

    static func image(_ artwork: CompanionArtwork) -> UIImage {
        if let cached = cache.object(forKey: artwork.assetName as NSString) { return cached }
        guard let original = UIImage(named: artwork.assetName), let cg = original.cgImage else { return UIImage() }
        let width = cg.width, height = cg.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return original }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        var visited = [Bool](repeating: false, count: width * height)
        var queue: [Int] = []
        func enqueue(_ index: Int) {
            guard !visited[index] else { return }
            visited[index] = true
            let p = index * 4
            if pixels[p + 3] < 12 || (pixels[p] > 239 && pixels[p + 1] > 239 && pixels[p + 2] > 239) { queue.append(index) }
        }
        for x in 0..<width { enqueue(x); enqueue((height - 1) * width + x) }
        for y in 0..<height { enqueue(y * width); enqueue(y * width + width - 1) }
        var cursor = 0
        while cursor < queue.count {
            let index = queue[cursor]; cursor += 1
            let x = index % width, y = index / width
            if x > 0 { enqueue(index - 1) }; if x + 1 < width { enqueue(index + 1) }
            if y > 0 { enqueue(index - width) }; if y + 1 < height { enqueue(index + width) }
        }
        for index in queue { for channel in 0..<4 { pixels[index * 4 + channel] = 0 } }
        guard let output = context.makeImage() else { return original }
        let image = UIImage(cgImage: output, scale: original.scale, orientation: original.imageOrientation)
        cache.setObject(image, forKey: artwork.assetName as NSString)
        return image
    }
}
