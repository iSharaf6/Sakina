import Adhan
import Combine
import CoreLocation
import Foundation
import WidgetKit

enum PrayerCalculationError: LocalizedError {
    case invalidCoordinate
    case invalidTimeZone
    case calculationFailed(Date)

    var errorDescription: String? {
        switch self {
        case .invalidCoordinate:
            return "The selected location is invalid."
        case .invalidTimeZone:
            return "The selected location does not have a valid time zone."
        case let .calculationFailed(date):
            return "Prayer times could not be calculated for \(date.formatted(date: .abbreviated, time: .omitted))."
        }
    }
}

/// Owns prayer calculation and shared widget persistence. Location permission is
/// requested only when `refreshUsingCurrentLocation` is called by the UI.
@MainActor
final class PrayerTimesService: ObservableObject {
    static let shared = PrayerTimesService()

    @Published private(set) var schedule: PrayerSchedule?
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?

    let locationService: PrayerLocationService

    init() {
        self.locationService = PrayerLocationService()
        self.schedule = SharedStore.prayerSchedule
    }

    init(locationService: PrayerLocationService) {
        self.locationService = locationService
        self.schedule = SharedStore.prayerSchedule
    }

    /// Contextual flow for a "Use my location" button.
    @discardableResult
    func refreshUsingCurrentLocation(
        settings: PrayerCalculationSettings = .default
    ) async -> PrayerSchedule? {
        guard !isRefreshing else { return schedule }
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }

        do {
            let location = try await locationService.requestCurrentLocation()
            return try refresh(for: location, settings: settings)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Manual-city flow. Coordinates are consumed for calculation but never
    /// copied into the App Group schedule.
    @discardableResult
    func refresh(
        for location: PrayerCalculationLocation,
        settings: PrayerCalculationSettings = .default,
        now: Date = .now
    ) throws -> PrayerSchedule {
        do {
            let newSchedule = try Self.calculateSchedule(
                for: location,
                settings: settings,
                now: now
            )
            UserDefaults.standard.set(["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude,
                                       "zone": location.timeZone.identifier, "label": location.displayName], forKey: "prayer.localCalculationLocation")
            schedule = newSchedule
            SharedStore.prayerSchedule = newSchedule
            ReminderScheduler.refresh()
            // The schedule powers the Home Screen widget plus both paired
            // Lock Screen halves, so invalidate them as one atomic update.
            WidgetCenter.shared.reloadAllTimelines()
            errorMessage = nil
            return newSchedule
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Refreshes using the last selected location kept only in this app's private defaults.
    func refreshSavedLocation() {
        guard let stored = UserDefaults.standard.dictionary(forKey: "prayer.localCalculationLocation"),
              let latitude = stored["latitude"] as? Double, let longitude = stored["longitude"] as? Double,
              let zone = stored["zone"] as? String, let timeZone = TimeZone(identifier: zone), let label = stored["label"] as? String else { return }
        var settings = PrayerCalculationSettings.default
        let defaults = UserDefaults.standard
        settings.method = PrayerCalculationMethod(rawValue: defaults.string(forKey: SettingsKeys.prayerCalculationMethod) ?? "") ?? .muslimWorldLeague
        settings.asrMethod = PrayerAsrMethod(rawValue: defaults.string(forKey: SettingsKeys.prayerAsrMethod) ?? "") ?? .standard
        settings.highLatitudePreference = PrayerHighLatitudePreference(rawValue: defaults.string(forKey: SettingsKeys.prayerHighLatitude) ?? "") ?? .automatic
        _ = try? refresh(for: PrayerCalculationLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), timeZone: timeZone, displayName: label), settings: settings)
    }

    func reloadSharedSchedule() {
        schedule = SharedStore.prayerSchedule
    }

    static func calculateSchedule(
        for location: PrayerCalculationLocation,
        settings: PrayerCalculationSettings = .default,
        now: Date = .now
    ) throws -> PrayerSchedule {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        guard CLLocationCoordinate2DIsValid(location.coordinate),
              (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw PrayerCalculationError.invalidCoordinate
        }
        guard !location.timeZone.identifier.isEmpty else {
            throw PrayerCalculationError.invalidTimeZone
        }

        let coordinates = Coordinates(latitude: latitude, longitude: longitude)
        var parameters = settings.method.adhanMethod.params
        parameters.madhab = settings.asrMethod.adhanMadhab
        parameters.highLatitudeRule = settings.highLatitudePreference.adhanRule
        parameters.adjustments = PrayerAdjustments(
            fajr: settings.adjustments.fajr,
            sunrise: settings.adjustments.sunrise,
            dhuhr: settings.adjustments.dhuhr,
            asr: settings.adjustments.asr,
            maghrib: settings.adjustments.maghrib,
            isha: settings.adjustments.isha
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timeZone
        let firstDay = calendar.startOfDay(for: now)
        var days: [PrayerDaySchedule] = []

        // Today plus the following seven local calendar days.
        for offset in 0...7 {
            guard let dayStart = calendar.date(byAdding: .day, value: offset, to: firstDay) else {
                throw PrayerCalculationError.calculationFailed(firstDay)
            }
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: dayStart)
            guard let calculated = PrayerTimes(
                coordinates: coordinates,
                date: dateComponents,
                calculationParameters: parameters
            ) else {
                throw PrayerCalculationError.calculationFailed(dayStart)
            }

            let events = [
                PrayerEvent(kind: .fajr, time: calculated.fajr),
                PrayerEvent(kind: .sunrise, time: calculated.sunrise),
                PrayerEvent(kind: .dhuhr, time: calculated.dhuhr),
                PrayerEvent(kind: .asr, time: calculated.asr),
                PrayerEvent(kind: .maghrib, time: calculated.maghrib),
                PrayerEvent(kind: .isha, time: calculated.isha),
            ]
            days.append(PrayerDaySchedule(dayStart: dayStart, events: events))
        }

        guard let finalDay = days.last?.dayStart,
              let expiresAt = calendar.date(byAdding: .day, value: 1, to: finalDay) else {
            throw PrayerCalculationError.calculationFailed(firstDay)
        }

        let label = location.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return PrayerSchedule(
            generatedAt: now,
            expiresAt: expiresAt,
            locationLabel: label.isEmpty ? "Selected location" : label,
            timeZoneIdentifier: location.timeZone.identifier,
            calculationMethodID: settings.method.rawValue,
            asrMethodID: settings.asrMethod.rawValue,
            days: days
        )
    }
}

private extension PrayerCalculationMethod {
    var adhanMethod: Adhan.CalculationMethod {
        switch self {
        case .muslimWorldLeague: return .muslimWorldLeague
        case .egyptian: return .egyptian
        case .karachi: return .karachi
        case .ummAlQura: return .ummAlQura
        case .dubai: return .dubai
        case .moonsightingCommittee: return .moonsightingCommittee
        case .northAmerica: return .northAmerica
        case .kuwait: return .kuwait
        case .qatar: return .qatar
        case .singapore: return .singapore
        case .tehran: return .tehran
        case .turkey: return .turkey
        }
    }
}

private extension PrayerAsrMethod {
    var adhanMadhab: Adhan.Madhab {
        self == .hanafi ? .hanafi : .shafi
    }
}

private extension PrayerHighLatitudePreference {
    var adhanRule: Adhan.HighLatitudeRule? {
        switch self {
        case .automatic: return nil
        case .middleOfTheNight: return .middleOfTheNight
        case .seventhOfTheNight: return .seventhOfTheNight
        case .twilightAngle: return .twilightAngle
        }
    }
}
