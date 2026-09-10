import SwiftUI
import UIKit

/// Shared Arabic rendering for UIKit and SwiftUI. The default Uthmani text
/// uses Quran Foundation's QPC Unicode edition with its matching KFGQPC font.
/// Canonical text remains untouched for copy/search and Tajweed span offsets.
/// Legacy scripts fall back by complete word, never by isolated diacritic.
enum QuranTextRenderer {

    // MARK: Fonts

    /// The QPC Hafs face, paired with text_qpc_hafs. Three marks used by
    /// the legacy text_uthmani encoding are unsupported (see fallbackMarks).
    static let uthmaniFontName = "KFGQPC HAFS Uthmanic Script"

    /// The Complex's pre-shaped Madani font, driven by `HafsSmartStore`.
    static let smartFontName = "KFGQPC Hafs Smart"

    static func smartFont(size: CGFloat) -> UIFont {
        UIFont(name: smartFontName, size: size) ?? uthmaniFont(size: size)
    }

    /// Whether this script draws the Complex's pre-shaped glyphs.
    static func usesSmartGlyphs(_ script: QuranScript) -> Bool {
        script == .uthmani && MushafLineStore.shared.pages.isEmpty
            && HafsSmartStore.shared.isLoaded && UIFont(name: smartFontName, size: 24) != nil
    }

    /// The smart glyph string split into the Arabic and its trailing ayah
    /// number (a right-to-left mark plus one glyph, preceded by a space).
    static func smartParts(_ text: String) -> (body: String, marker: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let space = trimmed.lastIndex(of: " ") else { return (trimmed, "") }
        return (String(trimmed[..<space]), String(trimmed[trimmed.index(after: space)...]))
    }

    /// The base font for a script. IndoPak falls back to the system font
    /// (see the type comment); the others use KFGQPC when it is installed.
    static func font(for script: QuranScript, size: CGFloat) -> UIFont {
        switch script {
        case .uthmani, .tajweed:
            return uthmaniFont(size: size)
        case .indopak:
            return UIFont.systemFont(ofSize: size)
        }
    }

    /// KFGQPC HAFS, or the system font if the bundle lost it.
    static func uthmaniFont(size: CGFloat) -> UIFont {
        UIFont(name: uthmaniFontName, size: size) ?? UIFont.systemFont(ofSize: size)
    }

    /// The font used for `fallbackMarks`: the system Arabic face draws
    /// them as proper small marks above or below the letter.
    static func markFont(size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size)
    }

    // MARK: Broken marks

    /// Every Arabic mark whose glyph in the bundled KFGQPC font is the
    /// oversized `uni0600` placeholder (fonttools, September 2026). In the
    /// bundled Uthmani text only U+06DF, U+06E3 and U+06EB occur, but the
    /// Tajweed text comes from the same font family so the whole broken
    /// block is listed:
    ///
    /// - U+0610–061A  small high signs (sallallahou alayhe wasallam … small kasra)
    /// - U+0658–065D  mark noon ghunna, zwarakay, vowel signs
    /// - U+065F       wavy hamza below
    /// - U+06DF       small high rounded zero (sifr mustadir)
    /// - U+06E3       small low seen
    /// - U+06EB       empty centre high stop
    /// - U+06EE/06EF  dal / reh with inverted V
    ///
    /// Stored as `Character`s as the public shape; matching happens on
    /// unicode scalars because a combining mark never stands alone as a
    /// `Character` once it follows a letter.
    /// Marks the bundled KFGQPC build cannot draw (it maps them to the
    /// U+0600 placeholder), borrowed from the system font instead: the sifr
    /// mustadir, the small low seen and the empty centre high stop. These are
    /// the only three code points in the whole text it lacks.
    static let fallbackMarks: Set<Character> = ["\u{06DF}", "\u{06E3}", "\u{06EB}"]

    private static let fallbackScalars: Set<Unicode.Scalar> = Set(fallbackMarks.flatMap { $0.unicodeScalars })

    static func isFallbackMark(_ scalar: Unicode.Scalar) -> Bool {
        fallbackScalars.contains(scalar)
    }

    // MARK: Tajweed

    /// A stretch of text and the tajweed colour it carries, if any.
    struct Run: Equatable {
        let text: String
        let color: UIColor?
    }

    /// The Quran.com tajweed palette, keyed by the `class` value inside
    /// `<tajweed class=…>`. Unknown classes get no colour.
    static let tajweedPalette: [String: UIColor] = [
        "ham_wasl": UIColor(hex: 0xAAAAAA),
        "slnt": UIColor(hex: 0xAAAAAA),
        "silent": UIColor(hex: 0xAAAAAA),
        "laam_shamsiyah": UIColor(hex: 0xAAAAAA),
        "madda_normal": UIColor(hex: 0x537FFF),
        "madda_permissible": UIColor(hex: 0x4050FF),
        "madda_necessary": UIColor(hex: 0x000EBC),
        "qalaqah": UIColor(hex: 0xDD0008),
        "qalqalah": UIColor(hex: 0xDD0008),
        "madda_obligatory": UIColor(hex: 0x2144C1),
        "ikhafa_shafawi": UIColor(hex: 0xD500B7),
        "ikhafa": UIColor(hex: 0x9400A8),
        "idgham_shafawi": UIColor(hex: 0x58B800),
        "iqlab": UIColor(hex: 0x26BFFD),
        "idgham_ghunnah": UIColor(hex: 0x169777),
        "idgham_wo_ghunnah": UIColor(hex: 0x169200),
        "idgham_mutajanisayn": UIColor(hex: 0xA1A1A1),
        "idgham_mutaqaribayn": UIColor(hex: 0xA1A1A1),
        "ghunnah": UIColor(hex: 0xFF7E1E),
    ]

    static func tajweedColor(forClass name: String) -> UIColor? {
        tajweedPalette[name.lowercased()]
    }

    /// The Uthmani text cut into runs at the span boundaries, each span
    /// coloured by its rule class. Spans are UTF-16 offsets into `text`;
    /// overlapping or out-of-range spans are clipped so the runs always
    /// concatenate back to `text` byte for byte.
    static func tajweedRuns(for text: String, spans: [TajweedSpan]) -> [Run] {
        let whole = text as NSString
        let length = whole.length
        var runs: [Run] = []

        func append(_ range: NSRange, _ colour: UIColor?) {
            guard range.length > 0 else { return }
            let piece = whole.substring(with: range)
            if let last = runs.last, last.color == colour {
                runs[runs.count - 1] = Run(text: last.text + piece, color: colour)
            } else {
                runs.append(Run(text: piece, color: colour))
            }
        }

        var cursor = 0
        for span in spans.sorted(by: { $0.s < $1.s }) {
            let start = min(max(span.s, cursor), length)
            let end = min(max(span.s + span.l, start), length)
            guard end > start else { continue }
            append(NSRange(location: cursor, length: start - cursor), nil)
            append(NSRange(location: start, length: end - start), tajweedColor(forClass: span.c))
            cursor = end
        }
        append(NSRange(location: cursor, length: length - cursor), nil)
        return runs
    }

    /// Parses Quran.com `text_uthmani_tajweed`: plain Uthmani text with
    /// `<tajweed class=NAME>…</tajweed>` around each rule (the attribute may
    /// be quoted or not). Any other tag (`<span class=end>`, `<rule>`…)
    /// is dropped and its text kept. HTML entities are unescaped. Runs
    /// with the same colour are merged.
    static func tajweedRuns(fromHTML html: String) -> [Run] {
        var runs: [Run] = []
        var colours: [UIColor?] = []
        var text = ""

        func flush() {
            guard !text.isEmpty else { return }
            let colour = colours.last ?? nil
            if let last = runs.last, last.color == colour {
                runs[runs.count - 1] = Run(text: last.text + text, color: colour)
            } else {
                runs.append(Run(text: text, color: colour))
            }
            text = ""
        }

        var index = html.startIndex
        while index < html.endIndex {
            let character = html[index]
            if character == "<", let close = html[index...].firstIndex(of: ">") {
                let tag = html[html.index(after: index)..<close]
                flush()
                handle(tag: tag, colours: &colours)
                index = html.index(after: close)
            } else if character == "&", let semicolon = html[index...].firstIndex(of: ";"),
                      html.distance(from: index, to: semicolon) <= 10 {
                let entity = html[html.index(after: index)..<semicolon]
                if let unescaped = unescape(entity: entity) {
                    text.append(unescaped)
                } else {
                    text.append(contentsOf: html[index...semicolon])
                }
                index = html.index(after: semicolon)
            } else {
                text.append(character)
                index = html.index(after: index)
            }
        }
        flush()
        return runs
    }

    private static func handle(tag: Substring, colours: inout [UIColor?]) {
        let body = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        let closing = body.hasPrefix("/")
        let name = body.drop(while: { $0 == "/" })
            .prefix { !$0.isWhitespace && $0 != "/" }
            .lowercased()
        guard name == "tajweed" || name == "rule" else { return }
        if closing {
            if !colours.isEmpty { colours.removeLast() }
            return
        }
        colours.append(attribute("class", in: body).flatMap(tajweedColor(forClass:)))
    }

    /// The value of `name=value` or `name="value"` inside a tag body.
    private static func attribute(_ name: String, in tag: String) -> String? {
        guard let range = tag.range(of: "\(name)=", options: .caseInsensitive) else { return nil }
        var rest = tag[range.upperBound...]
        var quote: Character?
        if let first = rest.first, first == "\"" || first == "'" {
            quote = first
            rest = rest.dropFirst()
        }
        let value = rest.prefix { character in
            if let quote { return character != quote }
            return !character.isWhitespace && character != ">" && character != "/"
        }
        return value.isEmpty ? nil : String(value)
    }

    private static func unescape(entity: Substring) -> String? {
        switch entity {
        case "amp": return "&"
        case "lt": return "<"
        case "gt": return ">"
        case "quot": return "\""
        case "apos": return "'"
        case "nbsp": return "\u{00A0}"
        default:
            guard entity.hasPrefix("#") else { return nil }
            let number = entity.dropFirst()
            let value: UInt32?
            if number.hasPrefix("x") || number.hasPrefix("X") {
                value = UInt32(number.dropFirst(), radix: 16)
            } else {
                value = UInt32(number)
            }
            return value.flatMap(Unicode.Scalar.init).map { String(Character($0)) }
        }
    }

    // MARK: Resolving the script

    /// The runs of an ayah in the requested script, plus the script that
    /// was actually used: Tajweed and IndoPak fall back to Uthmani when the
    /// scripts file has no entry for the ayah.
    static func runs(for ayah: QuranAyah, script: QuranScript) -> (script: QuranScript, runs: [Run]) {
        switch script {
        case .uthmani:
            return (.uthmani, [Run(text: MushafLineStore.shared.text(for: ayah.key) ?? ayah.displayArabic, color: nil)])
        case .tajweed:
            // Spans index the verbatim `arabic`; the edges are trimmed
            // afterwards so the letters match `displayArabic` exactly.
            guard let spans = QuranScriptStore.shared.tajweedSpans(for: ayah.key), !spans.isEmpty else {
                return (.uthmani, [Run(text: MushafLineStore.shared.text(for: ayah.key) ?? ayah.displayArabic, color: nil)])
            }
            let runs = trimmingEdges(tajweedRuns(for: ayah.arabic, spans: spans))
            return runs.isEmpty ? (.uthmani, [Run(text: ayah.displayArabic, color: nil)]) : (.tajweed, runs)
        case .indopak:
            guard let raw = QuranScriptStore.shared.indopak(for: ayah.key) else {
                return (.uthmani, [Run(text: MushafLineStore.shared.text(for: ayah.key) ?? ayah.displayArabic, color: nil)])
            }
            // Quran.com's IndoPak text carries Private Use Area pause glyphs
            // (U+E01A…E022) that only its own font can draw; iOS shows some
            // as emoji. Without that font they are dropped, along with the
            // zero-width and directional controls around them.
            let text = String(raw.unicodeScalars.filter { scalar in
                !(0xE000...0xF8FF).contains(scalar.value) && ![0x200B, 0x200F, 0xFEFF].contains(scalar.value)
            }).replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            let runs = strippingTrailingMarker([Run(text: text, color: nil)])
            return runs.isEmpty ? (.uthmani, [Run(text: ayah.displayArabic, color: nil)]) : (.indopak, runs)
        }
    }

    /// Whether a scalar is part of an ayah number the API may have left at
    /// the end of the text: any digit system, the end-of-ayah sign, or the
    /// ornate parentheses.
    private static func isMarkerScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x30...0x39, 0x0660...0x0669, 0x06F0...0x06F9: return true
        case 0x06DD, 0xFD3E, 0xFD3F: return true
        default: return scalar.properties.isWhitespace
        }
    }

    /// Drops the edge whitespace the API leaves around the text, the way
    /// `QuranAyah.displayArabic` does, without touching anything inside.
    static func trimmingEdges(_ runs: [Run]) -> [Run] {
        let blank = CharacterSet.whitespacesAndNewlines
        var result = runs
        while let last = result.last {
            var scalars = Array(last.text.unicodeScalars)
            while let tail = scalars.last, blank.contains(tail) { scalars.removeLast() }
            if scalars.isEmpty { result.removeLast(); continue }
            var view = String.UnicodeScalarView()
            view.append(contentsOf: scalars)
            result[result.count - 1] = Run(text: String(view), color: last.color)
            break
        }
        while let first = result.first {
            let scalars = Array(first.text.unicodeScalars.drop { blank.contains($0) })
            if scalars.isEmpty { result.removeFirst(); continue }
            var view = String.UnicodeScalarView()
            view.append(contentsOf: scalars)
            result[0] = Run(text: String(view), color: first.color)
            break
        }
        return result
    }

    /// Removes a trailing ayah number (and the whitespace around it) so the
    /// KFGQPC marker is not drawn twice. Edge whitespace is trimmed as
    /// `displayArabic` does; the Qur'an text itself is untouched.
    static func strippingTrailingMarker(_ runs: [Run]) -> [Run] {
        var result = runs
        while let last = result.last {
            var scalars = Array(last.text.unicodeScalars)
            while let tail = scalars.last, isMarkerScalar(tail) { scalars.removeLast() }
            if scalars.isEmpty {
                result.removeLast()
            } else {
                var view = String.UnicodeScalarView()
                view.append(contentsOf: scalars)
                result[result.count - 1] = Run(text: String(view), color: last.color)
                break
            }
        }
        if let first = result.first {
            let trimmed = first.text.drop { $0.isWhitespace }
            if trimmed.isEmpty {
                result.removeFirst()
            } else {
                result[0] = Run(text: String(trimmed), color: first.color)
            }
        }
        return result
    }

    // MARK: Pieces

    /// A run split further by font: `isMark` pieces are drawn in the
    /// system font because the KFGQPC glyph is broken.
    struct Piece: Equatable {
        let text: String
        let color: UIColor?
        let isMark: Bool
    }

    /// A fallback must cover the whole word, including its base letters.
    /// Switching font for a combining mark alone destroys its positioning.
    /// QPC display text needs no fallback; this protects legacy Tajweed text
    /// without altering the canonical string or its colour-span offsets.
    static func pieces(for runs: [Run], script: QuranScript) -> [Piece] {
        guard script != .indopak else {
            return runs.map { Piece(text: $0.text, color: $0.color, isMark: false) }
        }
        let full = runs.map(\.text).joined()
        let ns = full as NSString
        let words = (try? NSRegularExpression(pattern: "\\S+"))?.matches(in: full, range: NSRange(location: 0, length: ns.length)) ?? []
        let fallbackRanges = words.map(\.range).filter {
            ns.substring(with: $0).unicodeScalars.contains(where: isFallbackMark)
        }
        var offset = 0
        var result: [Piece] = []
        for run in runs {
            var buffer = ""
            var fallback = false
            for character in run.text {
                let needsFallback = fallbackRanges.contains { NSLocationInRange(offset, $0) }
                if needsFallback != fallback, !buffer.isEmpty {
                    result.append(Piece(text: buffer, color: run.color, isMark: fallback))
                    buffer = ""
                }
                fallback = needsFallback
                buffer.append(character)
                offset += String(character).utf16.count
            }
            if !buffer.isEmpty { result.append(Piece(text: buffer, color: run.color, isMark: fallback)) }
        }
        return result
    }

    // MARK: UIKit

    struct Style {
        var script: QuranScript
        var fontSize: CGFloat
        var ink: UIColor
        /// Colour of the ayah number; `ink` when nil.
        var markerColor: UIColor? = nil
        /// Drawn behind the Arabic (not the marker) as `.backgroundColor`.
        var background: UIColor? = nil

        init(script: QuranScript, fontSize: CGFloat, ink: UIColor, markerColor: UIColor? = nil, background: UIColor? = nil) {
            self.script = script
            self.fontSize = fontSize
            self.ink = ink
            self.markerColor = markerColor
            self.background = background
        }
    }

    /// The ayah's Arabic in the chosen script with fonts and colours, and
    /// optionally " " plus the ayah number. Paragraph styles are left to
    /// the caller.
    static func attributed(_ ayah: QuranAyah, style: Style, includeMarker: Bool = true) -> NSAttributedString {
        if usesSmartGlyphs(style.script), let smart = HafsSmartStore.shared.text(for: ayah.key) {
            let parts = smartParts(smart)
            let font = smartFont(size: style.fontSize)
            let result = NSMutableAttributedString(string: parts.body, attributes: [.font: font, .foregroundColor: style.ink])
            if let background = style.background, result.length > 0 {
                result.addAttribute(.backgroundColor, value: background, range: NSRange(location: 0, length: result.length))
            }
            if includeMarker, !parts.marker.isEmpty {
                result.append(NSAttributedString(string: " ", attributes: [.font: font, .foregroundColor: style.ink]))
                result.append(NSAttributedString(string: parts.marker, attributes: [
                    .font: font,
                    .foregroundColor: style.markerColor ?? style.ink,
                ]))
            }
            return result
        }
        let resolved = runs(for: ayah, script: style.script)
        let baseFont = font(for: resolved.script, size: style.fontSize)
        let fallbackFont = markFont(size: style.fontSize)
        let result = NSMutableAttributedString()

        for piece in pieces(for: resolved.runs, script: resolved.script) {
            result.append(NSAttributedString(string: piece.text, attributes: [
                .font: piece.isMark ? fallbackFont : baseFont,
                .foregroundColor: piece.color ?? style.ink,
            ]))
        }
        if let background = style.background, result.length > 0 {
            result.addAttribute(.backgroundColor, value: background, range: NSRange(location: 0, length: result.length))
        }

        if includeMarker {
            let markerFont = uthmaniFont(size: style.fontSize)
            result.append(NSAttributedString(string: " ", attributes: [
                .font: baseFont,
                .foregroundColor: style.ink,
            ]))
            result.append(NSAttributedString(string: ayah.marker, attributes: [
                .font: markerFont,
                .foregroundColor: style.markerColor ?? style.ink,
            ]))
        }
        return result
    }

    /// The UTF-16 range of the ayah number inside `attributed(…)` output
    /// built with `includeMarker: true`.
    static func markerRange(in attributed: NSAttributedString, ayah: QuranAyah) -> NSRange {
        var length = (ayah.marker as NSString).length
        if attributed.length > 0,
           let font = attributed.attribute(.font, at: attributed.length - 1, effectiveRange: nil) as? UIFont,
           font.familyName == smartFontName,
           let smart = HafsSmartStore.shared.text(for: ayah.key) {
            length = (smartParts(smart).marker as NSString).length
        }
        return NSRange(location: max(0, attributed.length - length), length: min(length, attributed.length))
    }

    // MARK: SwiftUI

    /// The same content for `Text(...)`, built with SwiftUI attributes
    /// (SwiftUI's `Text` ignores UIKit-scoped fonts and colours, so the
    /// `NSAttributedString` is not converted). Sizes follow Dynamic Type
    /// through `UIFontMetrics`, so the letters, the fallback marks and the
    /// marker grow together.
    static func swiftUI(_ ayah: QuranAyah, script: QuranScript, size: CGFloat,
                        ink: Color = .yqInk, markerColor: Color = .yqAccentDeep,
                        includeMarker: Bool = true) -> AttributedString {
        let scaled = UIFontMetrics(forTextStyle: textStyle(for: size)).scaledValue(for: size)
        if usesSmartGlyphs(script), let smart = HafsSmartStore.shared.text(for: ayah.key) {
            let parts = smartParts(smart)
            let font: Font = .custom(smartFontName, fixedSize: scaled)
            // The glyph codes are private-use (bidi class L). SwiftUI's Text
            // resolves the paragraph direction differently from TextKit, so
            // force right-to-left with an override that ends after the marker.
            var result = AttributedString("\u{202E}" + parts.body)
            result.font = font
            result.foregroundColor = ink
            if includeMarker, !parts.marker.isEmpty {
                var space = AttributedString(" "); space.font = font; space.foregroundColor = ink
                var marker = AttributedString(parts.marker); marker.font = font; marker.foregroundColor = markerColor
                result.append(space); result.append(marker)
            }
            var end = AttributedString("\u{202C}"); end.font = font
            result.append(end)
            return result
        }
        let resolved = runs(for: ayah, script: script)
        let baseFont: Font = resolved.script == .indopak
            ? .system(size: scaled)
            : .custom(uthmaniFontName, fixedSize: scaled)
        let fallbackFont: Font = .system(size: scaled)
        let markerFont: Font = .custom(uthmaniFontName, fixedSize: scaled)

        var result = AttributedString()
        for piece in pieces(for: resolved.runs, script: resolved.script) {
            var part = AttributedString(piece.text)
            part.font = piece.isMark ? fallbackFont : baseFont
            part.foregroundColor = piece.color.map { Color(uiColor: $0) } ?? ink
            result.append(part)
        }
        if includeMarker {
            var space = AttributedString(" ")
            space.font = baseFont
            space.foregroundColor = ink
            result.append(space)
            var marker = AttributedString(ayah.marker)
            marker.font = markerFont
            marker.foregroundColor = markerColor
            result.append(marker)
        }
        return result
    }

    /// Mirrors `Font.arabic(_:)` so the sheet and library scale the way
    /// they did before.
    private static func textStyle(for size: CGFloat) -> UIFont.TextStyle {
        switch size {
        case 30...: return .title1
        case 24...: return .title2
        case 20...: return .title3
        case 16...: return .body
        case 13...: return .subheadline
        default: return .footnote
        }
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
