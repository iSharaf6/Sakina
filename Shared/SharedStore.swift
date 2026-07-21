import Foundation

/// State shared between the app and the widget extension through the App Group.
enum SharedStore {

    static let appGroupID = "group.com.islamsharaf.sakina"
    private static let pinnedKey = "pinnedSituationID"
    private static let prayerScheduleKey = "prayerSchedule.v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
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
