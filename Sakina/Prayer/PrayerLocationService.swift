import Combine
import CoreLocation
import Foundation

/// A location used transiently for prayer calculation. Coordinates remain in
/// app memory and are deliberately excluded from `PrayerSchedule`.
struct PrayerCalculationLocation {
    let coordinate: CLLocationCoordinate2D
    let timeZone: TimeZone
    let displayName: String
}

enum PrayerLocationError: LocalizedError {
    case permissionDenied
    case permissionRestricted
    case requestAlreadyInProgress
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access is off. Choose a city manually or enable location in Settings."
        case .permissionRestricted:
            return "Location access is restricted on this device. Choose a city manually instead."
        case .requestAlreadyInProgress:
            return "A location request is already in progress."
        case .locationUnavailable:
            return "Your location could not be determined. Please try again or choose a city manually."
        }
    }
}

/// Requests When-In-Use access only in response to `requestCurrentLocation()`.
/// Constructing this service never presents a permission prompt.
@MainActor
final class PrayerLocationService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var latestLocation: PrayerCalculationLocation?
    @Published private(set) var errorMessage: String?

    private let manager: CLLocationManager
    private let geocoder = CLGeocoder()
    private var continuation: CheckedContinuation<PrayerCalculationLocation, Error>?

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.authorizationStatus = manager.authorizationStatus
        super.init()

        manager.delegate = self
        // Prayer calculations do not need street-level precision.
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Call from an explicit user action such as "Use my location".
    func requestCurrentLocation() async throws -> PrayerCalculationLocation {
        guard continuation == nil else { throw PrayerLocationError.requestAlreadyInProgress }
        errorMessage = nil

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            beginRequest(for: manager.authorizationStatus)
        }
    }

    private func beginRequest(for status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied:
            finish(with: .failure(PrayerLocationError.permissionDenied))
        case .restricted:
            finish(with: .failure(PrayerLocationError.permissionRestricted))
        @unknown default:
            finish(with: .failure(PrayerLocationError.locationUnavailable))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        guard continuation != nil else { return }
        beginRequest(for: manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations
            .filter({ $0.horizontalAccuracy >= 0 })
            .max(by: { $0.timestamp < $1.timestamp }) else {
            finish(with: .failure(PrayerLocationError.locationUnavailable))
            return
        }

        Task { @MainActor in
            let placemark = try? await geocoder.reverseGeocodeLocation(location).first
            let resolved = PrayerCalculationLocation(
                coordinate: location.coordinate,
                timeZone: placemark?.timeZone ?? .current,
                displayName: Self.cityLevelName(from: placemark)
            )
            latestLocation = resolved
            finish(with: .success(resolved))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: .failure(PrayerLocationError.locationUnavailable))
    }

    private func finish(with result: Result<PrayerCalculationLocation, Error>) {
        guard let continuation else { return }
        self.continuation = nil

        if case let .failure(error) = result {
            errorMessage = error.localizedDescription
        }
        continuation.resume(with: result)
    }

    private static func cityLevelName(from placemark: CLPlacemark?) -> String {
        guard let placemark else { return "Current location" }
        if let locality = placemark.locality, let region = placemark.administrativeArea,
           locality.localizedCaseInsensitiveCompare(region) != .orderedSame {
            return "\(locality), \(region)"
        }
        return placemark.locality
            ?? placemark.administrativeArea
            ?? placemark.country
            ?? "Current location"
    }
}
