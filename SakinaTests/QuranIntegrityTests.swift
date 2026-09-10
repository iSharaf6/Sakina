import XCTest
@testable import Sakina

/// Structural and textual integrity of the bundled `quran.json`.
///
/// The Arabic and translation are never edited by hand; these tests make sure
/// the file is the complete mushaf and that every ayah shared with the frozen
/// `verses.json` is byte for byte identical.
final class QuranIntegrityTests: XCTestCase {
    /// Ayah count of each surah, 1...114.
    private let canonicalCounts = [
        7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
        112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
        54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
        14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
        29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
        11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
    ]

    private let store = QuranStore.shared

    func testCanonicalCounts() {
        XCTAssertTrue(store.isLoaded, "quran.json failed to load")
        XCTAssertEqual(canonicalCounts.count, QuranStore.surahCount)
        XCTAssertEqual(canonicalCounts.reduce(0, +), QuranStore.ayahCount)

        XCTAssertEqual(store.surahs.count, QuranStore.surahCount)
        XCTAssertEqual(store.ayat.count, QuranStore.ayahCount)
        XCTAssertEqual(store.surahs.map(\.number), Array(1...QuranStore.surahCount))

        for (index, surah) in store.surahs.enumerated() {
            let expected = canonicalCounts[index]
            XCTAssertEqual(surah.versesCount, expected, "surah \(surah.number) versesCount")
            let ayat = store.ayat(in: surah.number)
            XCTAssertEqual(ayat.count, expected, "surah \(surah.number) ayah count")
            XCTAssertEqual(ayat.map(\.ayah), Array(1...expected), "surah \(surah.number) numbering")
            XCTAssertEqual(surah.bismillahPre, !(surah.number == 1 || surah.number == 9), "surah \(surah.number) bismillah")
            XCTAssertTrue(surah.revelationPlace == "makkah" || surah.revelationPlace == "madinah", "surah \(surah.number) place")
            XCTAssertFalse(surah.nameArabic.isEmpty)
            XCTAssertFalse(surah.nameSimple.isEmpty)
            XCTAssertFalse(surah.nameTranslated.isEmpty)
        }

        let keys = store.ayat.map(\.key)
        XCTAssertEqual(Set(keys).count, keys.count, "ayah keys must be unique")
        for ayah in store.ayat {
            XCTAssertEqual(ayah.key, "\(ayah.surah):\(ayah.ayah)")
        }
    }

    func testPagesAndJuz() {
        let pages = store.ayat.map(\.page)
        let juz = store.ayat.map(\.juz)

        XCTAssertEqual(Set(pages), Set(1...QuranStore.pageCount), "every page 1...604 must appear")
        XCTAssertEqual(Set(juz), Set(1...QuranStore.juzCount), "every juz 1...30 must appear")
        XCTAssertEqual(pages, pages.sorted(), "page numbers must be non-decreasing in mushaf order")
        XCTAssertEqual(juz, juz.sorted(), "juz numbers must be non-decreasing in mushaf order")

        XCTAssertEqual(store.firstAyah(ofJuz: 1)?.key, "1:1")
        XCTAssertEqual(store.firstAyah(ofJuz: 2)?.key, "2:142")
        XCTAssertEqual(store.firstAyah(ofJuz: 30)?.key, "78:1")
        XCTAssertEqual(store.firstAyah(onPage: 1)?.key, "1:1")
        XCTAssertEqual(store.firstAyah(onPage: 604)?.surah, 112)
        XCTAssertEqual(store.ayat.last?.page, 604)
        XCTAssertEqual(store.ayat.last?.juz, 30)
    }

    func testMatchesFrozenVerses() {
        let frozen = VerseStore.shared.all
        XCTAssertFalse(frozen.isEmpty, "verses.json failed to load")
        for verse in frozen {
            guard let ayah = store.ayah(verse.key) else {
                XCTFail("\(verse.key) from verses.json is missing from quran.json")
                continue
            }
            XCTAssertEqual(ayah.surah, verse.surah, verse.key)
            XCTAssertEqual(ayah.ayah, verse.ayah, verse.key)
            XCTAssertEqual(ayah.audioFile, verse.audioFile, verse.key)
            // Swift `==` on String uses canonical equivalence; compare the
            // UTF-8 bytes so a normalisation or whitespace change cannot slip through.
            XCTAssertTrue(Array(ayah.arabic.utf8) == Array(verse.arabic.utf8), "\(verse.key) Arabic differs from verses.json")
            XCTAssertTrue(Array(ayah.translation.utf8) == Array(verse.translation.utf8), "\(verse.key) translation differs from verses.json")
        }
    }

    func testNoHTMLOrEmptyText() {
        for ayah in store.ayat {
            XCTAssertFalse(ayah.arabic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(ayah.key) empty Arabic")
            XCTAssertFalse(ayah.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(ayah.key) empty translation")
            XCTAssertFalse(ayah.translation.contains("<"), "\(ayah.key) translation contains HTML")
            XCTAssertFalse(ayah.translation.contains(">"), "\(ayah.key) translation contains HTML")
            XCTAssertNil(ayah.translation.range(of: "&[a-zA-Z#0-9]+;", options: .regularExpression), "\(ayah.key) translation contains an HTML entity")
            XCTAssertFalse(ayah.arabic.contains("\n"), "\(ayah.key) Arabic contains a newline")
            XCTAssertFalse(ayah.translation.contains("\n"), "\(ayah.key) translation contains a newline")
        }
        XCTAssertTrue(store.ayah("1:1")?.arabic.hasPrefix("بِسْمِ ٱللَّهِ") ?? false)
        XCTAssertTrue(store.ayah("2:255")?.arabic.hasPrefix("ٱللَّهُ لَآ إِلَـٰهَ") ?? false)
    }

    func testStoreLookups() {
        XCTAssertEqual(store.surah(1)?.nameSimple, "Al-Fatihah")
        XCTAssertEqual(store.surah(114)?.number, 114)
        XCTAssertNil(store.surah(0))
        XCTAssertNil(store.surah(115))

        XCTAssertEqual(store.ayah(surah: 2, number: 255)?.key, "2:255")
        XCTAssertNil(store.ayah("2:287"))
        XCTAssertNil(store.ayah("115:1"))

        // Across a surah boundary.
        XCTAssertEqual(store.next(after: "1:7")?.key, "2:1")
        XCTAssertEqual(store.previous(before: "2:1")?.key, "1:7")
        XCTAssertEqual(store.next(after: "2:286")?.key, "3:1")
        XCTAssertNil(store.previous(before: "1:1"))
        XCTAssertNil(store.next(after: "114:6"))
        XCTAssertEqual(store.index(of: "1:1"), 0)
        XCTAssertEqual(store.index(of: "114:6"), QuranStore.ayahCount - 1)

        XCTAssertEqual(store.firstAyah(ofJuz: 2)?.key, "2:142")
        XCTAssertEqual(store.firstAyah(ofJuz: 30)?.key, "78:1")
        XCTAssertNil(store.firstAyah(ofJuz: 31))

        XCTAssertEqual(store.sorted(["114:1", "2:255", "1:1"]), ["1:1", "2:255", "114:1"])
        XCTAssertEqual(store.sorted(["114:1", "2:255", "nope"]), ["2:255", "114:1"])

        XCTAssertEqual(store.ayat(onPage: 1).map(\.key), (1...7).map { "1:\($0)" })
        XCTAssertTrue(store.surahs(inJuz: 30).map(\.number).contains(78))
        XCTAssertTrue(store.surahs(inJuz: 30).map(\.number).contains(114))
    }
}
