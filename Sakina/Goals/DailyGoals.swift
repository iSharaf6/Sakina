import Foundation

// MARK: - Goal

/// One small invitation for the day. A goal may open a collection to read
/// (`practice`), or it may simply be ticked, like sadaqah or praying on time.
struct DailyGoal: Identifiable, Hashable {
    let id: String
    let symbol: String
    let artwork: CompanionArtwork?
    let practice: DuaPractice?
    private let titleEN: String
    private let titleAR: String
    private let detailEN: String
    private let detailAR: String

    init(id: String, symbol: String, artwork: CompanionArtwork? = nil, practice: DuaPractice? = nil,
         title: (String, String), detail: (String, String)) {
        self.id = id
        self.symbol = symbol
        self.artwork = artwork
        self.practice = practice
        self.titleEN = title.0
        self.titleAR = title.1
        self.detailEN = detail.0
        self.detailAR = detail.1
    }

    func title(_ language: AppLanguage) -> String { language.pick(titleEN, titleAR) }
    func detail(_ language: AppLanguage) -> String { language.pick(detailEN, detailAR) }

    static func == (lhs: DailyGoal, rhs: DailyGoal) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Catalog

/// The default day, in the order it unfolds.
enum DailyGoalCatalog {
    static let defaults: [DailyGoal] = [
        DailyGoal(id: "wake", symbol: "sunrise.fill", artwork: .morning, practice: .morning,
                  title: ("Remembrance on waking", "ذكر الاستيقاظ"),
                  detail: ("The first words of the day.", "أول كلمات اليوم.")),
        DailyGoal(id: "after-fajr", symbol: "checkmark.seal.fill", artwork: .fajr, practice: .afterSalah,
                  title: ("Dhikr after Fajr", "أذكار بعد الفجر"),
                  detail: ("Stay a little after the salam.", "تمهّل بعد السلام.")),
        DailyGoal(id: "morning", symbol: "sun.horizon.fill", artwork: .morning, practice: .morning,
                  title: ("Morning adhkar", "أذكار الصباح"),
                  detail: ("Begin the day with remembrance.", "ابدأ يومك بالذكر.")),
        DailyGoal(id: "duha", symbol: "sun.max.fill", artwork: .sunrise, practice: nil,
                  title: ("Duha prayer", "صلاة الضحى"),
                  detail: ("Two rak’ahs once the sun is up.", "ركعتان بعد ارتفاع الشمس.")),
        DailyGoal(id: "after-dhuhr", symbol: "checkmark.seal.fill", artwork: .dhuhr, practice: .afterSalah,
                  title: ("Dhikr after Dhuhr", "أذكار بعد الظهر"),
                  detail: ("A pause in the middle of the day.", "وقفة في منتصف اليوم.")),
        DailyGoal(id: "after-asr", symbol: "checkmark.seal.fill", artwork: .asr, practice: .afterSalah,
                  title: ("Dhikr after Asr", "أذكار بعد العصر"),
                  detail: ("Before the afternoon slips away.", "قبل أن ينقضي العصر.")),
        DailyGoal(id: "afternoon", symbol: "leaf.fill", artwork: .anytime, practice: .anytime,
                  title: ("Afternoon dhikr", "ذكر بعد الظهيرة"),
                  detail: ("Little words, any time.", "كلمات يسيرة في أي وقت.")),
        DailyGoal(id: "after-maghrib", symbol: "checkmark.seal.fill", artwork: .maghrib, practice: .afterSalah,
                  title: ("Dhikr after Maghrib", "أذكار بعد المغرب"),
                  detail: ("As the day softens into evening.", "مع انحدار النهار إلى المساء.")),
        DailyGoal(id: "sadaqa", symbol: "heart.fill", artwork: .ummah, practice: nil,
                  title: ("Sadaqah", "صدقة"),
                  detail: ("Give something, however small.", "أعطِ ولو القليل.")),
        DailyGoal(id: "quran", symbol: "book.closed.fill", artwork: .quran, practice: .quran,
                  title: ("Read Qur’an", "قراءة القرآن"),
                  detail: ("A page, an ayah, a moment.", "صفحة أو آية أو لحظة.")),
        DailyGoal(id: "fard", symbol: "clock.badge.checkmark.fill", artwork: .salah, practice: nil,
                  title: ("Five prayers on time", "الفرائض في وقتها"),
                  detail: ("Each one as it comes in.", "كل صلاة في وقتها.")),
        DailyGoal(id: "sleep", symbol: "moon.stars.fill", artwork: .sleep, practice: .sleep,
                  title: ("Dhikr before sleep", "أذكار النوم"),
                  detail: ("Leave the day with Allah.", "اختم يومك بذكر الله."))
    ]

    static func goal(_ id: String) -> DailyGoal? { defaults.first { $0.id == id } }
}

// MARK: - Day formatting

private enum GoalDay {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func string(_ date: Date) -> String { formatter.string(from: date) }

    /// Days at or after this are kept; older pairs are dropped on write.
    static func horizon(from date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let cutoff = calendar.date(byAdding: .day, value: -60, to: date) ?? date
        return string(cutoff)
    }
}

// MARK: - Goal log

/// Which goals were ticked on which day, on this device only.
/// Stored as `yyyy-MM-dd:goalID` pairs joined by `|`; the last 60 days are kept.
enum GoalLog {
    static let key = "yaqeen.goalLog"

    private static func pairs(_ raw: String) -> [String] {
        raw.split(separator: "|").map(String.init).filter { !$0.isEmpty }
    }

    private static func entry(_ id: String, on date: Date) -> String {
        "\(GoalDay.string(date)):\(id)"
    }

    static func isDone(_ id: String, on date: Date = .now, in raw: String) -> Bool {
        pairs(raw).contains(entry(id, on: date))
    }

    /// Flips one goal for the day and prunes anything older than 60 days.
    static func toggling(_ id: String, on date: Date = .now, in raw: String) -> String {
        let entry = entry(id, on: date)
        let horizon = GoalDay.horizon(from: date)
        var kept = pairs(raw).filter { pair in
            let day = String(pair.prefix(while: { $0 != ":" }))
            return day.count == 10 && day >= horizon
        }
        if let index = kept.firstIndex(of: entry) {
            kept.remove(at: index)
        } else {
            kept.append(entry)
        }
        return kept.joined(separator: "|")
    }

    static func doneIDs(on date: Date = .now, in raw: String) -> Set<String> {
        let prefix = GoalDay.string(date) + ":"
        return Set(pairs(raw).filter { $0.hasPrefix(prefix) }.map { String($0.dropFirst(prefix.count)) })
    }

    /// Fraction of the enabled goals ticked today, 0...1. Empty lists read as 0.
    static func progress(enabled: [DailyGoal], on date: Date = .now, in raw: String) -> Double {
        guard !enabled.isEmpty else { return 0 }
        let done = doneIDs(on: date, in: raw)
        let count = enabled.filter { done.contains($0.id) }.count
        return Double(count) / Double(enabled.count)
    }
}

// MARK: - Preferences

/// Which goals the person has kept. Stored as goal ids joined by `|`.
/// An empty string means every default is enabled; `"-"` means none.
enum GoalPreferences {
    static let key = "yaqeen.goalsEnabled"
    static let none = "-"

    private static func ids(_ raw: String) -> [String] {
        raw.split(separator: "|").map(String.init).filter { !$0.isEmpty }
    }

    static func enabled(from raw: String) -> [DailyGoal] {
        let chosen = ids(raw)
        if chosen.isEmpty { return DailyGoalCatalog.defaults }
        let set = Set(chosen)
        return DailyGoalCatalog.defaults.filter { set.contains($0.id) }
    }

    static func isEnabled(_ id: String, in raw: String) -> Bool {
        let chosen = ids(raw)
        return chosen.isEmpty || chosen.contains(id)
    }

    /// Flips one goal. The result is always written explicitly, in catalog
    /// order, so turning a goal off from the all-enabled state keeps the rest.
    static func toggling(_ id: String, in raw: String) -> String {
        var set = Set(enabled(from: raw).map(\.id))
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        let ordered = DailyGoalCatalog.defaults.map(\.id).filter { set.contains($0) }
        return ordered.isEmpty ? none : ordered.joined(separator: "|")
    }
}
