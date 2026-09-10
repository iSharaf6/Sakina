import Foundation
import SwiftUI

// MARK: - Scripts

/// How the Arabic is written. Uthmani is the verified base text; Tajweed
/// is the same text with colour-coded rules; IndoPak is the South Asian
/// orthography. All three come from Quran.com API v4 and are never edited.
enum QuranScript: String, CaseIterable, Identifiable, Codable {
    case uthmani, tajweed, indopak
    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .uthmani: return language.pick("Uthmani", "عثماني")
        case .tajweed: return language.pick("Tajweed", "تجويد")
        case .indopak: return language.pick("IndoPak", "هندي")
        }
    }

    func detail(_ language: AppLanguage) -> String {
        switch self {
        case .uthmani: return language.pick("Madani mushaf script", "رسم مصحف المدينة")
        case .tajweed: return language.pick("Rules shown in colour", "أحكام التجويد بالألوان")
        case .indopak: return language.pick("South Asian script", "الرسم الهندي الباكستاني")
        }
    }
}

// MARK: - Translations

struct QuranTranslationEdition: Identifiable, Hashable, Codable {
    /// The Quran.com resource id, e.g. 20 for Saheeh International.
    let id: Int
    let name: String
    let author: String
    /// Lowercased language name as Quran.com reports it, e.g. "english".
    let language: String

    static let saheehInternational = QuranTranslationEdition(id: 20, name: "Saheeh International", author: "Saheeh International", language: "english")
}

/// The extra translations bundled in `translations.json`. Saheeh
/// International lives in `quran.json` and is always available.
final class QuranTranslationStore {
    static let shared = QuranTranslationStore()

    private struct File: Codable {
        struct Ayah: Codable {
            let k: String
            let t: [String: String]
        }
        let source: String
        let fetched: String
        let editions: [QuranTranslationEdition]
        let ayat: [Ayah]
    }

    let source: String
    let extraEditions: [QuranTranslationEdition]
    private let byKey: [String: [String: String]]

    private init() {
        guard let url = Bundle.main.url(forResource: "translations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            source = ""; extraEditions = []; byKey = [:]
            return
        }
        source = file.source
        extraEditions = file.editions
        byKey = Dictionary(uniqueKeysWithValues: file.ayat.map { ($0.k, $0.t) })
    }

    /// Saheeh International first, then the bundled editions in file order.
    var editions: [QuranTranslationEdition] { [.saheehInternational] + extraEditions }

    func edition(_ id: Int) -> QuranTranslationEdition? { editions.first { $0.id == id } }

    /// The translation of one ayah in the chosen edition, falling back to
    /// Saheeh International when the edition is missing.
    func text(for ayah: QuranAyah, edition id: Int) -> String {
        if id == QuranTranslationEdition.saheehInternational.id { return ayah.translation }
        return byKey[ayah.key]?[String(id)] ?? ayah.translation
    }

    static func warmUp() {
        Task.detached(priority: .utility) { _ = QuranTranslationStore.shared }
    }
}

// MARK: - Alternate scripts

/// One tajweed rule over a range of the verified Uthmani text.
struct TajweedSpan: Codable, Hashable {
    /// Start offset in UTF-16 units of `QuranAyah.arabic` (all code points here are BMP).
    let s: Int
    let l: Int
    /// Quran.com rule class, e.g. "ikhafa", "qalaqah", "madda_necessary".
    let c: String
    var range: NSRange { NSRange(location: s, length: l) }
}

/// Tajweed spans and IndoPak text from `quran-scripts.json`. The tajweed
/// classes were projected onto the verified Uthmani text at build time, so
/// the Arabic drawn in Tajweed mode is byte-identical to Uthmani mode.
final class QuranScriptStore {
    static let shared = QuranScriptStore()

    private struct File: Codable {
        struct Ayah: Codable {
            let k: String
            let tj: [TajweedSpan]
            /// Quran.com `text_indopak`.
            let ip: String
        }
        let source: String
        let fetched: String
        let ayat: [Ayah]
    }

    let source: String
    private let tajweed: [String: [TajweedSpan]]
    private let indopak: [String: String]

    private init() {
        guard let url = Bundle.main.url(forResource: "quran-scripts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            source = ""; tajweed = [:]; indopak = [:]
            return
        }
        source = file.source
        tajweed = Dictionary(uniqueKeysWithValues: file.ayat.map { ($0.k, $0.tj) })
        indopak = Dictionary(uniqueKeysWithValues: file.ayat.map { ($0.k, $0.ip) })
    }

    var isLoaded: Bool { !indopak.isEmpty }

    func tajweedSpans(for key: String) -> [TajweedSpan]? { tajweed[key] }
    func indopak(for key: String) -> String? { indopak[key] }

    static func warmUp() {
        Task.detached(priority: .utility) { _ = QuranScriptStore.shared }
    }
}

// MARK: - Hafs Smart (KFGQPC)

/// The King Fahd Complex's own "Hafs Smart" rendering of every ayah:
/// pre-shaped glyph codes for the KFGQPC Hafs Smart font, so the Madani
/// mushaf's letters, marks and ayah numbers appear exactly as printed. It is
/// display data only; search, copy, share and tajweed keep using the
/// verified Uthmani text in `QuranAyah.arabic`.
final class HafsSmartStore {
    static let shared = HafsSmartStore()

    struct Ayah: Codable {
        let k: String
        /// Right-to-left mark + glyph code pairs, spaces, trailing number glyph.
        let t: String
        let p: Int
        let ls: Int
        let le: Int
    }

    private struct File: Codable {
        let source: String
        let fetched: String
        let ayat: [Ayah]
    }

    let source: String
    private let byKey: [String: Ayah]

    private init() {
        guard let url = Bundle.main.url(forResource: "hafs-smart", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            source = ""; byKey = [:]
            return
        }
        source = file.source
        byKey = Dictionary(uniqueKeysWithValues: file.ayat.map { ($0.k, $0) })
    }

    var isLoaded: Bool { !byKey.isEmpty }

    /// The glyph string including the trailing ayah number.
    func text(for key: String) -> String? { byKey[key]?.t }

    /// Madani page and the lines the ayah occupies on it.
    func placement(for key: String) -> (page: Int, lineStart: Int, lineEnd: Int)? {
        byKey[key].map { ($0.p, $0.ls, $0.le) }
    }

    static func warmUp() {
        Task.detached(priority: .utility) { _ = HafsSmartStore.shared }
    }
}

// MARK: - Reader preferences

/// Everything the Display sheet controls, persisted in UserDefaults.
enum MushafPreferences {
    static let scriptKey = "yaqeen.mushaf.script"
    static let translationKey = "yaqeen.mushaf.translation"
    static let showTranslationKey = "yaqeen.mushaf.showTranslation"
    static let fontScaleKey = "yaqeen.mushaf.fontScale"
    static let layoutKey = "yaqeen.mushaf.layout"
    static let directionKey = "yaqeen.mushaf.direction"

    enum Layout: String, CaseIterable, Identifiable, Codable {
        /// Madani mushaf pages, 604 of them.
        case page
        /// One surah as flowing text.
        case surah
        var id: String { rawValue }
        func title(_ language: AppLanguage) -> String {
            switch self {
            case .page: return language.pick("Pages", "صفحات")
            case .surah: return language.pick("Surah", "سورة")
            }
        }
    }

    enum Direction: String, CaseIterable, Identifiable, Codable {
        case horizontal, vertical
        var id: String { rawValue }
        func title(_ language: AppLanguage) -> String {
            switch self {
            case .horizontal: return language.pick("Swipe sideways", "تصفّح أفقي")
            case .vertical: return language.pick("Scroll down", "تمرير عمودي")
            }
        }
    }

    static let fontScaleRange: ClosedRange<Double> = 0.75...1.8
}
