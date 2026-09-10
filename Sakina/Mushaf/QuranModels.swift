import Foundation

// MARK: - Models
//
// The complete Qur'an, loaded from the bundled `quran.json`. The Arabic is
// Quran.com API v4 Uthmani text and the translation is Saheeh International
// with footnote markers removed. Neither field is ever edited by hand; the
// integrity tests compare every ayah shared with `verses.json` byte for byte.

struct QuranSurah: Identifiable, Hashable, Codable {
    let number: Int
    let nameArabic: String
    let nameSimple: String
    let nameTranslated: String
    /// "makkah" or "madinah".
    let revelationPlace: String
    let versesCount: Int
    /// Whether the basmalah is written before the surah (false for 1 and 9).
    let bismillahPre: Bool

    var id: Int { number }

    func name(_ language: AppLanguage) -> String {
        language == .arabic ? nameArabic : nameSimple
    }

    func placeName(_ language: AppLanguage) -> String {
        revelationPlace == "madinah" ? language.pick("Madinah", "مدنية") : language.pick("Makkah", "مكية")
    }

    enum CodingKeys: String, CodingKey {
        case number = "n", nameArabic = "ar", nameSimple = "en", nameTranslated = "tr"
        case revelationPlace = "place", versesCount = "count", bismillahPre = "bismillah"
    }
}

struct QuranAyah: Identifiable, Hashable, Codable {
    /// "2:255"
    let key: String
    let surah: Int
    let ayah: Int
    /// Uthmani script from Quran.com API v4 (`text_uthmani`).
    let arabic: String
    /// Saheeh International.
    let translation: String
    /// Madani mushaf page, 1...604.
    let page: Int
    /// 1...30.
    let juz: Int

    var id: String { key }

    /// The Arabic with the API's edge whitespace removed. `arabic` itself is
    /// kept verbatim so the integrity tests stay byte-exact.
    var displayArabic: String { arabic.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Zero padded "002255" for the everyayah recitation CDN.
    var audioFile: String { String(format: "%03d%03d", surah, ayah) }

    /// The ayah number in Arabic-Indic digits.
    var arabicNumber: String { QuranAyah.arabicDigits(ayah) }

    /// The end-of-ayah marker. The KFGQPC HAFS font draws Arabic-Indic
    /// digits inside the ornate ayah frame, so the digits alone are the
    /// marker; adding U+06DD would draw a second, empty frame.
    var marker: String { arabicNumber }

    func reference(_ language: AppLanguage) -> String {
        let name = QuranStore.shared.surah(surah)?.name(language) ?? "\(surah)"
        return language == .arabic ? "\(name) \(QuranAyah.arabicDigits(surah)):\(arabicNumber)" : "\(name) \(key)"
    }

    var canonicalURL: String { "https://quran.com/\(surah)/\(ayah)" }

    static func arabicDigits(_ value: Int) -> String {
        let digits = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(value).compactMap { $0.wholeNumberValue.map { digits[$0] } }.joined()
    }

    enum CodingKeys: String, CodingKey {
        case key = "k", surah = "s", ayah = "a", arabic = "t", translation = "tr", page = "p", juz = "j"
    }
}

// MARK: - Store

final class QuranStore {
    static let shared = QuranStore()

    static let surahCount = 114
    static let ayahCount = 6236
    static let juzCount = 30
    static let pageCount = 604

    private struct File: Codable {
        let source: String
        let fetched: String
        let surahs: [QuranSurah]
        let ayat: [QuranAyah]
    }

    let source: String
    let fetched: String
    let surahs: [QuranSurah]
    /// Every ayah in mushaf order.
    let ayat: [QuranAyah]

    private let byKey: [String: QuranAyah]
    private let bySurah: [Int: [QuranAyah]]
    private let indexByKey: [String: Int]
    private let juzStartIndex: [Int: Int]
    private let pageStartIndex: [Int: Int]

    private init() {
        guard let url = Bundle.main.url(forResource: "quran", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            assertionFailure("quran.json missing from bundle")
            source = ""; fetched = ""; surahs = []; ayat = []
            byKey = [:]; bySurah = [:]; indexByKey = [:]; juzStartIndex = [:]; pageStartIndex = [:]
            return
        }
        source = file.source
        fetched = file.fetched
        surahs = file.surahs
        ayat = file.ayat
        byKey = Dictionary(uniqueKeysWithValues: file.ayat.map { ($0.key, $0) })
        bySurah = Dictionary(grouping: file.ayat, by: \.surah)
        indexByKey = Dictionary(uniqueKeysWithValues: file.ayat.enumerated().map { ($1.key, $0) })
        var juz: [Int: Int] = [:]
        var page: [Int: Int] = [:]
        for (index, ayah) in file.ayat.enumerated() {
            if juz[ayah.juz] == nil { juz[ayah.juz] = index }
            if page[ayah.page] == nil { page[ayah.page] = index }
        }
        juzStartIndex = juz
        pageStartIndex = page
    }

    /// Decode on a background thread before the first screen needs it.
    static func warmUp() {
        Task.detached(priority: .utility) { _ = QuranStore.shared }
    }

    var isLoaded: Bool { !ayat.isEmpty }

    func surah(_ number: Int) -> QuranSurah? {
        guard number >= 1, number <= surahs.count else { return nil }
        return surahs[number - 1]
    }

    func ayat(in surah: Int) -> [QuranAyah] { bySurah[surah] ?? [] }

    func ayah(_ key: String) -> QuranAyah? { byKey[key] }

    func ayah(surah: Int, number: Int) -> QuranAyah? { byKey["\(surah):\(number)"] }

    func index(of key: String) -> Int? { indexByKey[key] }

    func next(after key: String) -> QuranAyah? {
        guard let index = indexByKey[key], index + 1 < ayat.count else { return nil }
        return ayat[index + 1]
    }

    func previous(before key: String) -> QuranAyah? {
        guard let index = indexByKey[key], index > 0 else { return nil }
        return ayat[index - 1]
    }

    func firstAyah(ofJuz juz: Int) -> QuranAyah? {
        juzStartIndex[juz].map { ayat[$0] }
    }

    func firstAyah(onPage page: Int) -> QuranAyah? {
        pageStartIndex[page].map { ayat[$0] }
    }

    func ayat(onPage page: Int) -> [QuranAyah] {
        ayat.filter { $0.page == page }
    }

    /// The surahs that begin inside a juz, for the juz picker.
    func surahs(inJuz juz: Int) -> [QuranSurah] {
        let numbers = Set(ayat.filter { $0.juz == juz }.map(\.surah))
        return surahs.filter { numbers.contains($0.number) }
    }

    /// Sort keys into mushaf order.
    func sorted(_ keys: some Sequence<String>) -> [String] {
        keys.compactMap { key in indexByKey[key].map { ($0, key) } }.sorted { $0.0 < $1.0 }.map(\.1)
    }
}
