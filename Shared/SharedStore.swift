import Foundation

/// State shared between the app and the widget extension through the App Group.
enum SharedStore {

    static let appGroupID = "group.com.islamsharaf.sakina"
    private static let pinnedKey = "pinnedSituationID"
    private static let prayerScheduleKey = "prayerSchedule.v1"
    private static let practiceProgressKey = "widgetPracticeProgress.v1"
    private static let widgetLanguageKey = "widgetLanguage.v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static var widgetLanguage: AppLanguage? {
        get { defaults.string(forKey: widgetLanguageKey).flatMap(AppLanguage.init(rawValue:)) }
        set {
            if let newValue { defaults.set(newValue.rawValue, forKey: widgetLanguageKey) }
            else { defaults.removeObject(forKey: widgetLanguageKey) }
        }
    }

    // MARK: Pinned situation (widget)

    static var pinnedSituationID: String? {
        get { defaults.string(forKey: pinnedKey) }
        set {
            if let newValue { defaults.set(newValue, forKey: pinnedKey) }
            else { defaults.removeObject(forKey: pinnedKey) }
        }
    }

    static var pinnedSituation: Situation? {
        pinnedSituationID.flatMap { SituationCatalog.by(id: $0) }
    }

    // MARK: Prayer schedule (widget)

    /// A city-level, coordinate-free schedule prepared by the containing app.
    static var prayerSchedule: PrayerSchedule? {
        get {
            guard let data = defaults.data(forKey: prayerScheduleKey) else { return nil }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            return try? decoder.decode(PrayerSchedule.self, from: data)
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: prayerScheduleKey)
                return
            }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            guard let data = try? encoder.encode(newValue) else { return }
            defaults.set(data, forKey: prayerScheduleKey)
        }
    }

    static func clearPrayerSchedule() {
        prayerSchedule = nil
    }

    // MARK: Reader completion (widget)

    /// Returns today's actual completion state, or an uncompleted state when
    /// the app has not written one for the requested local day.
    static func practiceProgress(on date: Date = .now, calendar: Calendar = .autoupdatingCurrent,
                                 in storage: UserDefaults = defaults) -> WidgetPracticeProgress {
        guard let data = storage.data(forKey: practiceProgressKey),
              let progress = try? JSONDecoder().decode(WidgetPracticeProgress.self, from: data) else {
            return WidgetPracticeProgress(on: date, calendar: calendar)
        }
        return progress.current(on: date, calendar: calendar)
    }

    /// Whether a write occurred lets the app avoid spending widget refreshes
    /// when it returns to the foreground without any completion changes.
    @discardableResult
    static func savePracticeProgress(_ progress: WidgetPracticeProgress,
                                     in storage: UserDefaults = defaults) -> Bool {
        if let data = storage.data(forKey: practiceProgressKey),
           let existing = try? JSONDecoder().decode(WidgetPracticeProgress.self, from: data),
           existing == progress { return false }
        guard let data = try? JSONEncoder().encode(progress) else { return false }
        storage.set(data, forKey: practiceProgressKey)
        return true
    }

    // MARK: Verse of the day

    /// Deterministic daily pick: same verse for everyone on a given date,
    /// cycling through every situation in the catalog.
    static func situationOfTheDay(for date: Date = .now) -> Situation {
        let cal = Calendar(identifier: .gregorian)
        let day = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = cal.component(.year, from: date)
        let index = (day &+ year &* 31) % SituationCatalog.all.count
        return SituationCatalog.all[index]
    }
}
