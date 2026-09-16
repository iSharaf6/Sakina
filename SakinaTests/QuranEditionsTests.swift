import XCTest
import CoreText
import UIKit
import SwiftUI
@testable import Sakina

/// Guards the alternate scripts and the bundled translations. Tajweed is
/// stored as rule spans over the verified Uthmani text, so Tajweed mode can
/// never draw different letters from Uthmani mode.
final class QuranEditionsTests: XCTestCase {
    private let store = QuranStore.shared
    private let scripts = QuranScriptStore.shared
    private let translations = QuranTranslationStore.shared

    func testScriptsCoverEveryAyah() {
        XCTAssertTrue(scripts.isLoaded, "quran-scripts.json failed to load")
        XCTAssertEqual(store.ayat.count, QuranStore.ayahCount)
        for ayah in store.ayat {
            XCTAssertNotNil(scripts.tajweedSpans(for: ayah.key), "\(ayah.key) has no tajweed spans")
            let indopak = scripts.indopak(for: ayah.key) ?? ""
            XCTAssertFalse(indopak.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(ayah.key) empty IndoPak")
            XCTAssertFalse(indopak.contains("<"), "\(ayah.key) IndoPak carries markup")
        }
    }

    func testTajweedSpansStayInsideTheUthmaniText() {
        var spanCount = 0
        for ayah in store.ayat {
            let length = (ayah.arabic as NSString).length
            var lastEnd = 0
            for span in scripts.tajweedSpans(for: ayah.key) ?? [] {
                XCTAssertGreaterThan(span.l, 0, "\(ayah.key) empty span")
                XCTAssertGreaterThanOrEqual(span.s, lastEnd, "\(ayah.key) spans overlap or are out of order")
                XCTAssertLessThanOrEqual(span.s + span.l, length, "\(ayah.key) span past the end of the text")
                XCTAssertFalse(span.c.isEmpty, "\(ayah.key) span without a class")
                lastEnd = span.s + span.l
                spanCount += 1
            }
        }
        XCTAssertGreaterThan(spanCount, 50_000, "far fewer tajweed spans than expected")
        // A few well-known rules must be present.
        let classes = Set(store.ayat.flatMap { scripts.tajweedSpans(for: $0.key) ?? [] }.map(\.c))
        for expected in ["ham_wasl", "madda_necessary", "qalaqah", "ikhafa", "ghunnah", "idgham_ghunnah", "iqlab"] {
            XCTAssertTrue(classes.contains(expected), "missing tajweed class \(expected)")
        }
    }

    func testTajweedNeverChangesTheLetters() {
        // Rendering tajweed concatenates the spans and the gaps between them
        // back into the verbatim Uthmani string.
        for ayah in store.ayat.prefix(600) {
            let text = ayah.arabic as NSString
            var rebuilt = ""
            var cursor = 0
            for span in scripts.tajweedSpans(for: ayah.key) ?? [] {
                if span.s > cursor { rebuilt += text.substring(with: NSRange(location: cursor, length: span.s - cursor)) }
                rebuilt += text.substring(with: span.range)
                cursor = span.s + span.l
            }
            if cursor < text.length { rebuilt += text.substring(from: cursor) }
            XCTAssertTrue(Array(rebuilt.utf8) == Array(ayah.arabic.utf8), "\(ayah.key) tajweed runs do not rebuild the Uthmani text")
        }
    }

    func testTranslationEditions() {
        let ids = Set(translations.editions.map(\.id))
        XCTAssertEqual(translations.editions.count, 9)
        XCTAssertEqual(ids, [20, 85, 22, 19, 203, 84, 95, 149, 54])
        XCTAssertEqual(translations.editions.first?.id, 20, "Saheeh International must come first")
        guard let kursi = store.ayah("2:255") else { return XCTFail("2:255 missing") }
        var differing = 0
        for edition in translations.editions where edition.id != 20 {
            let text = translations.text(for: kursi, edition: edition.id)
            XCTAssertFalse(text.isEmpty, "\(edition.name) has no text for 2:255")
            if text != kursi.translation { differing += 1 }
        }
        XCTAssertGreaterThanOrEqual(differing, 7, "extra editions should not fall back to Saheeh for 2:255")
        XCTAssertEqual(translations.text(for: kursi, edition: 999_999), kursi.translation, "unknown edition falls back to Saheeh")
    }

    func testHafsSmartCoversEveryAyah() {
        let smart = HafsSmartStore.shared
        XCTAssertTrue(smart.isLoaded, "hafs-smart.json failed to load")
        var numberGlyph: [Int: Character] = [:]
        for ayah in store.ayat {
            guard let text = smart.text(for: ayah.key) else { XCTFail("\(ayah.key) has no Hafs Smart text"); continue }
            let parts = QuranTextRenderer.smartParts(text)
            XCTAssertFalse(parts.body.isEmpty, "\(ayah.key) empty smart body")
            XCTAssertEqual(parts.marker.unicodeScalars.count, 2, "\(ayah.key) marker should be RLM + one glyph")
            // Only private-use glyphs, spaces and right-to-left marks may appear.
            for scalar in text.unicodeScalars where !(0xE000...0xF8FF).contains(scalar.value) && scalar.value != 0x20 && scalar.value != 0x200F {
                XCTFail("\(ayah.key) unexpected scalar \(scalar) in smart text")
            }
            if let glyph = parts.marker.last {
                if let seen = numberGlyph[ayah.ayah] {
                    XCTAssertEqual(seen, glyph, "\(ayah.key) ayah-number glyph differs from other ayat numbered \(ayah.ayah)")
                } else {
                    numberGlyph[ayah.ayah] = glyph
                }
            }
            XCTAssertNotNil(smart.placement(for: ayah.key))
        }
        XCTAssertEqual(numberGlyph.count, 286)
    }

    func testNoHTMLInTranslations() {
        for (index, ayah) in store.ayat.enumerated() where index % 50 == 0 {
            for edition in translations.editions {
                let text = translations.text(for: ayah, edition: edition.id)
                XCTAssertFalse(text.contains("<") || text.contains(">"), "\(ayah.key) \(edition.name) carries markup")
                XCTAssertFalse(text.isEmpty, "\(ayah.key) \(edition.name) empty")
            }
        }
    }
}

// The print renderer has a separate display encoding; verify its coverage,
// font compatibility, layout bounds and verse interactions independently.
extension QuranEditionsTests {
    func testPrintedEditionPreservesEveryWordAndMarker() {
        let pages = MushafLineStore.shared.pages
        XCTAssertEqual(pages.count, 604)
        var wordsByKey: [String: [MushafLineStore.Word]] = [:]
        for (index, words) in pages.enumerated() {
            XCTAssertFalse(words.isEmpty, "Empty page \(index + 1)")
            XCTAssertEqual(words.map(\.l), words.map(\.l).sorted())
            for word in words {
                XCTAssertTrue((1...15).contains(word.l))
                wordsByKey[word.k, default: []].append(word)
                XCTAssertFalse(word.t.unicodeScalars.contains(where: QuranTextRenderer.isFallbackMark),
                               "QPC text must not need the old font's mark fallback: \(word.k)")
            }
        }
        XCTAssertEqual(Set(wordsByKey.keys), Set(store.ayat.map(\.key)))
        for ayah in store.ayat {
            let words = wordsByKey[ayah.key] ?? []
            XCTAssertEqual(words.map(\.p), Array(1...words.count), ayah.key)
            XCTAssertEqual(words.filter(\.e).count, 1, ayah.key)
            XCTAssertEqual(words.last?.t, ayah.arabicNumber, ayah.key)
            XCTAssertNotNil(MushafLineStore.shared.page(for: ayah.key))
        }
        // The reference page is the modern Madani edition: 2:30 ends on line 3.
        XCTAssertEqual(pages[5].first { $0.k == "2:30" && $0.e }?.l, 3)
    }

    @MainActor
    func testPrintedFontContainsEveryDisplayCharacter() {
        let font = QuranTextRenderer.uthmaniFont(size: 24) as CTFont
        XCTAssertEqual(CTFontCopyPostScriptName(font) as String, "KFGQPCHAFSUthmanicScript-Regula")
        let characters = Set(MushafLineStore.shared.pages.flatMap { $0 }.flatMap { $0.t.utf16 })
        var chars = Array(characters)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        XCTAssertTrue(CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count))
        XCTAssertFalse(glyphs.contains(0))
        for key in ["2:22", "2:20", "49:5"] {
            guard let ayah = store.ayah(key) else { return XCTFail("Missing \(key)") }
            let text = QuranTextRenderer.attributed(ayah, style: .init(script: .uthmani, fontSize: 30, ink: .black), includeMarker: false)
            XCTAssertEqual(text.string, MushafLineStore.shared.text(for: key))
            let line = CTLineCreateWithAttributedString(text)
            for run in CTLineGetGlyphRuns(line) as! [CTRun] {
                let attributes = CTRunGetAttributes(run) as NSDictionary
                let actualFont = attributes[kCTFontAttributeName] as! CTFont
                XCTAssertEqual(CTFontCopyPostScriptName(actualFont) as String, CTFontCopyPostScriptName(font) as String,
                               "Unexpected fallback font in \(key)")
            }
        }
    }

    @MainActor
    func testEveryPrintedPageFitsAndKeepsVerseHitTargets() {
        let view = PrintedMushafCanvas(frame: CGRect(x: 0, y: 0, width: 315, height: 490))
        for page in 1...604 {
            view.configure(page: page, highlights: [:], playingKey: nil, colorMarkers: true, dark: false)
            view.layoutIfNeeded()
            XCTAssertEqual(view.positioned.count, MushafLineStore.shared.words(on: page).count)
            XCTAssertGreaterThan(view.renderedFontSize, 12, "Unreadable font on page \(page)")
            for item in view.positioned {
                XCTAssertGreaterThanOrEqual(item.rect.minX, -0.5, "Left overflow on page \(page)")
                XCTAssertLessThanOrEqual(item.rect.maxX, view.bounds.width + 0.5, "Right overflow on page \(page)")
                XCTAssertGreaterThanOrEqual(item.rect.minY, -0.5, "Top clipping on page \(page)")
                XCTAssertLessThanOrEqual(item.rect.maxY, view.bounds.height + 0.5, "Bottom clipping on page \(page)")
                let point = CGPoint(x: item.rect.midX, y: item.rect.midY)
                XCTAssertEqual(view.ayah(at: point)?.key, item.word.k, "Wrong tap target on page \(page)")
            }
        }
    }

    func testLegacyMarkFallbackNeverSplitsAWordAcrossFonts() {
        let original = "قَالُوا۟ رَبَّنَا"
        let pieces = QuranTextRenderer.pieces(for: [.init(text: original, color: nil)], script: .tajweed)
        XCTAssertEqual(pieces.map(\.text).joined(), original)
        XCTAssertEqual(pieces.first?.text, "قَالُوا۟")
        XCTAssertEqual(pieces.first?.isMark, true)
        XCTAssertEqual(pieces.last?.isMark, false)
    }

    @MainActor
    func testQuranicDuaRenderingPreservesEverySourceScalar() {
        let entries = DuaCollection.allEntries.filter { $0.kind == .quranic }
        XCTAssertFalse(entries.isEmpty)
        for entry in entries {
            let uiKit = QuranTextRenderer.attributedArabic(entry.arabic, size: 30, ink: .black)
            let swiftUI = QuranTextRenderer.swiftUIArabic(entry.arabic, size: 30)
            XCTAssertEqual(Array(uiKit.string.utf8), Array(entry.arabic.utf8), entry.id)
            XCTAssertEqual(Array(String(swiftUI.characters).utf8), Array(entry.arabic.utf8), entry.id)
        }
    }

    @MainActor
    func testRuqyahRoundedZerosUseOneCompatibleFontForThePassage() throws {
        let passage = try XCTUnwrap(RuqyahCatalog.quran.first { $0.id == "ruqyah-quran-2-102" })
        let rendered = QuranTextRenderer.attributedArabic(passage.arabic, size: 30, ink: .black)
        let source = rendered.string as NSString
        let words = try NSRegularExpression(pattern: "\\S+").matches(in: rendered.string,
            range: NSRange(location: 0, length: rendered.length))
        let markedWords = words.filter {
            source.substring(with: $0.range).unicodeScalars.contains { $0.value == 0x06DF }
        }
        // All six of these signs were visible as large dotted placeholders
        // in 2:102. The signs must survive and keep their base letters.
        XCTAssertEqual(markedWords.count, 6)
        let fullRange = NSRange(location: 0, length: rendered.length)
        rendered.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            let font = value as? UIFont
            XCTAssertEqual(font?.fontName, QuranTextRenderer.markFont(size: 30).fontName)
            XCTAssertEqual(range, fullRange,
                           "All words must use the same face while every recitation sign is retained")
        }
        let swiftUI = QuranTextRenderer.swiftUIArabic(passage.arabic, size: 30)
        XCTAssertEqual(swiftUI.runs.count, 1, "SwiftUI must also render the passage with one face")
    }

    @MainActor
    func testRuqyahShapingHasNoMissingOrPlaceholderGlyphs() {
        for entry in RuqyahCatalog.quran {
            let text = QuranTextRenderer.attributedArabic(entry.arabic, size: 30, ink: .black)
            let line = CTLineCreateWithAttributedString(text)
            for run in CTLineGetGlyphRuns(line) as! [CTRun] {
                let attributes = CTRunGetAttributes(run) as NSDictionary
                let font = attributes[kCTFontAttributeName] as! CTFont
                var glyphs = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
                CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
                XCTAssertFalse(glyphs.contains(0), "Missing glyph in \(entry.id)")
                // A font's cmap can report support while returning a
                // visible placeholder. Guard the *shaped* glyph stream,
                // not only whether the source has U+25CC in it.
                for scalar in [UniChar(0x25CC), UniChar(0x0600)] {
                    var character = scalar
                    var placeholder: CGGlyph = 0
                    if CTFontGetGlyphsForCharacters(font, &character, &placeholder, 1), placeholder != 0 {
                        XCTAssertFalse(glyphs.contains(placeholder),
                            "Placeholder U+\(String(scalar, radix: 16)) in \(entry.id), \(CTFontCopyPostScriptName(font))")
                        if let placeholderPath = CTFontCreatePathForGlyph(font, placeholder, nil) {
                            for glyph in Set(glyphs) {
                                // The bundled font assigns distinct glyph IDs
                                // to 06DF/06E3/06EB but duplicates 0600's
                                // placeholder outline, so IDs alone miss it.
                                XCTAssertNotEqual(CTFontCreatePathForGlyph(font, glyph, nil), placeholderPath,
                                                  "Placeholder outline in \(entry.id)")
                            }
                        }
                    }
                }
            }
        }
    }

    @MainActor
    func testSharedVerseCardsStayReadableAndBounded() throws {
        let ordered = SituationCatalog.all.sorted {
            ($0.primaryVerse?.arabic.count ?? 0) < ($1.primaryVerse?.arabic.count ?? 0)
        }
        let shortest = try XCTUnwrap(ordered.first)
        let longest = try XCTUnwrap(ordered.last)
        for situation in [shortest, longest] {
            for language in [AppLanguage.english, .arabic] {
                let renderer = ImageRenderer(content: VerseShareCard(
                    situation: situation, language: language, showTranslation: true
                ).environment(\.dynamicTypeSize, .accessibility5))
                renderer.scale = 1
                let image = try XCTUnwrap(renderer.uiImage)
                XCTAssertEqual(image.size.width, 430, accuracy: 1)
                XCTAssertGreaterThan(image.size.height, 200)
                XCTAssertLessThan(image.size.height, 1200,
                                  "A shared ayah should fit a readable portrait image")
                let attachment = XCTAttachment(image: image)
                attachment.name = "Share-\(situation.id)-\(language.rawValue)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
}

extension QuranEditionsTests {
    func testReadingPreferencesMigrateWithoutOverwritingSettings() {
        let name = "reader-migration-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(false, forKey: SettingsKeys.translationVisible)
        defaults.set(true, forKey: "yaqeen.mushaf.showTranslation")
        defaults.set(1.35, forKey: "yaqeen.mushaf.fontScale")
        defaults.set("indopak", forKey: MushafPreferences.scriptKey)
        MushafPreferences.migrate(defaults)
        XCTAssertFalse(defaults.bool(forKey: SettingsKeys.translationVisible))
        XCTAssertEqual(defaults.double(forKey: SettingsKeys.arabicScale), 1.35)
        XCTAssertEqual(defaults.string(forKey: MushafPreferences.presentationKey), "digital")
        defaults.set(1.6, forKey: SettingsKeys.arabicScale)
        MushafPreferences.migrate(defaults)
        XCTAssertEqual(defaults.double(forKey: SettingsKeys.arabicScale), 1.6)
        XCTAssertEqual(MushafPreferences.showTranslationKey, SettingsKeys.translationVisible)
        XCTAssertEqual(MushafPreferences.fontScaleKey, SettingsKeys.arabicScale)
    }

    func testTransliterationCoversTheWholeQuran() {
        XCTAssertEqual(Set(QuranTransliterationStore.shared.ayat.keys), Set(store.ayat.map(\.key)))
        for ayah in store.ayat {
            let text = QuranTransliterationStore.shared.text(for: ayah.key) ?? ""
            XCTAssertFalse(text.isEmpty, ayah.key)
            XCTAssertFalse(text.contains("<"), ayah.key)
        }
    }

    @MainActor
    func testIndoPakUsesItsOwnFontAndPreservesPauseSigns() {
        let font = QuranTextRenderer.font(for: .indopak, size: 30)
        XCTAssertEqual(font.fontName, QuranTextRenderer.indopakFontName)
        var privateSigns: Set<UInt32> = []
        var displayCharacters: Set<UInt16> = []
        for ayah in store.ayat {
            let raw = QuranScriptStore.shared.indopak(for: ayah.key) ?? ""
            let displayed = QuranTextRenderer.runs(for: ayah, script: .indopak).runs.map(\.text).joined()
            let expected = raw.unicodeScalars.filter { (0xE000...0xF8FF).contains($0.value) }.map(\.value)
            let actual = displayed.unicodeScalars.filter { (0xE000...0xF8FF).contains($0.value) }.map(\.value)
            XCTAssertEqual(actual, expected, ayah.key)
            privateSigns.formUnion(actual)
            displayCharacters.formUnion(displayed.utf16)
        }
        XCTAssertGreaterThan(privateSigns.count, 5)
        var chars = Array(displayCharacters)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        let complete = CTFontGetGlyphsForCharacters(font as CTFont, &chars, &glyphs, chars.count)
        XCTAssertTrue(complete, "Missing IndoPak characters: \(zip(chars, glyphs).filter { $0.1 == 0 }.map { String(format: "U+%04X", $0.0) })")
    }

    @MainActor
    func testDigitalScriptsReflowAtLargeSizes() {
        for script in QuranScript.allCases {
            for page in [1, 4, 93, 114, 516, 604] {
                let ayat = store.ayat(onPage: page)
                let regular = MushafTextView.measureHeight(ayat: ayat, width: 320, fontSize: 28, script: script, colorMarkers: true)
                let enlarged = MushafTextView.measureHeight(ayat: ayat, width: 320, fontSize: 50, script: script, colorMarkers: true)
                XCTAssertGreaterThan(regular, 0)
                XCTAssertTrue(enlarged.isFinite)
                XCTAssertGreaterThan(enlarged, regular, "\(script) page \(page) must grow instead of clipping")
            }
        }
    }
}
