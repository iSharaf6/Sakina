import Foundation

/// The six solar events displayed by Haneen. Sunrise is included for planning,
/// although it is not one of the five obligatory prayers.
enum PrayerKind: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    var englishName: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }

    var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    var symbolName: String {
        switch self {
        case .fajr: return "moon.stars.fill"
        case .sunrise: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.fill"
        }
    }

    func displayName(locale: Locale) -> String {
        locale.language.languageCode?.identifier == "ar" ? arabicName : englishName
    }
}

struct PrayerEvent: Codable, Hashable, Identifiable, Sendable {
    let kind: PrayerKind
    let time: Date

    var id: String { "\(kind.rawValue)-\(time.timeIntervalSince1970)" }
}

struct PrayerDaySchedule: Codable, Hashable, Identifiable, Sendable {
    /// Midnight at the requested location for this Gregorian day.
    let dayStart: Date
    let events: [PrayerEvent]

    var id: Date { dayStart }

    func time(for kind: PrayerKind) -> Date? {
        events.first { $0.kind == kind }?.time
    }
}

/// A privacy-conscious payload shared with WidgetKit. It intentionally contains
/// only a city-level label and calculated dates, never latitude or longitude.
struct PrayerSchedule: Codable, Hashable, Sendable {
    static let currentSchemaVersion = 1
    static let widgetKind = "YaqeenPrayerTimes"

    let schemaVersion: Int
    let generatedAt: Date
    let expiresAt: Date
    let locationLabel: String
    let timeZoneIdentifier: String
    let calculationMethodID: String
    let asrMethodID: String
    let days: [PrayerDaySchedule]

    init(
        schemaVersion: Int = PrayerSchedule.currentSchemaVersion,
        generatedAt: Date,
        expiresAt: Date,
        locationLabel: String,
        timeZoneIdentifier: String,
        calculationMethodID: String,
        asrMethodID: String,
        days: [PrayerDaySchedule]
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.expiresAt = expiresAt
        self.locationLabel = locationLabel
        self.timeZoneIdentifier = timeZoneIdentifier
        self.calculationMethodID = calculationMethodID
        self.asrMethodID = asrMethodID
        self.days = days.sorted { $0.dayStart < $1.dayStart }
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var allEvents: [PrayerEvent] {
        days.flatMap(\.events).sorted { $0.time < $1.time }
    }

    func events(on date: Date) -> [PrayerEvent] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return days.first { calendar.isDate($0.dayStart, inSameDayAs: date) }?.events ?? []
    }

    func nextEvent(after date: Date = .now) -> PrayerEvent? {
        allEvents.first { $0.time > date }
    }

    func followingEvent(after date: Date = .now) -> PrayerEvent? {
        let upcoming = allEvents.lazy.filter { $0.time > date }
        return upcoming.dropFirst().first
    }

    func isStale(at date: Date = .now) -> Bool {
        schemaVersion != Self.currentSchemaVersion || date >= expiresAt || nextEvent(after: date) == nil
    }

    static func placeholder(now: Date = .now, timeZone: TimeZone = .current) -> PrayerSchedule {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: now)
        let sampleHours: [(PrayerKind, Int, Int)] = [
            (.fajr, 5, 12), (.sunrise, 6, 38), (.dhuhr, 12, 8),
            (.asr, 15, 24), (.maghrib, 17, 42), (.isha, 19, 4),
        ]
        let days = (0...1).compactMap { offset -> PrayerDaySchedule? in
            guard let dayStart = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            let events = sampleHours.compactMap { kind, hour, minute -> PrayerEvent? in
                guard let time = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: dayStart
                ) else {
                    return nil
                }
                return PrayerEvent(kind: kind, time: time)
            }
            return PrayerDaySchedule(dayStart: dayStart, events: events)
        }
        let expiry = calendar.date(byAdding: .day, value: 2, to: start) ?? start.addingTimeInterval(172_800)
        return PrayerSchedule(
            generatedAt: now,
            expiresAt: expiry,
            locationLabel: "Sydney",
            timeZoneIdentifier: timeZone.identifier,
            calculationMethodID: "muslimWorldLeague",
            asrMethodID: "standard",
            days: days
        )
    }
}
