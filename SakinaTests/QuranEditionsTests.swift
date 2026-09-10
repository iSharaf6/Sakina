import XCTest
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
