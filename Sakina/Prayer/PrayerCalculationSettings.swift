import Foundation

enum PrayerCalculationMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case muslimWorldLeague
    case egyptian
    case karachi
    case ummAlQura
    case dubai
    case moonsightingCommittee
    case northAmerica
    case kuwait
    case qatar
    case singapore
    case tehran
    case turkey

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .muslimWorldLeague: return "Muslim World League"
        case .egyptian: return "Egyptian General Authority"
        case .karachi: return "University of Islamic Sciences, Karachi"
        case .ummAlQura: return "Umm al-Qura, Makkah"
        case .dubai: return "Dubai"
        case .moonsightingCommittee: return "Moonsighting Committee"
        case .northAmerica: return "ISNA, North America"
        case .kuwait: return "Kuwait"
        case .qatar: return "Qatar"
        case .singapore: return "Singapore"
        case .tehran: return "University of Tehran"
        case .turkey: return "Diyanet, Turkey"
        }
    }
}

enum PrayerAsrMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard
    case hanafi

    var id: String { rawValue }
    var displayName: String { self == .hanafi ? "Hanafi" : "Standard" }
}

enum PrayerHighLatitudePreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case automatic
    case middleOfTheNight
    case seventhOfTheNight
    case twilightAngle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .middleOfTheNight: return "Middle of the night"
        case .seventhOfTheNight: return "Seventh of the night"
        case .twilightAngle: return "Twilight angle"
        }
    }
}

struct PrayerMinuteAdjustments: Codable, Equatable, Sendable {
    var fajr = 0
    var sunrise = 0
    var dhuhr = 0
    var asr = 0
    var maghrib = 0
    var isha = 0
}

struct PrayerCalculationSettings: Codable, Equatable, Sendable {
    var method: PrayerCalculationMethod = .muslimWorldLeague
    var asrMethod: PrayerAsrMethod = .standard
    var highLatitudePreference: PrayerHighLatitudePreference = .automatic
    var adjustments = PrayerMinuteAdjustments()

    static let `default` = PrayerCalculationSettings()
}
