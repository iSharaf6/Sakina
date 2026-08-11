import Combine
import CoreLocation
import Foundation

enum QiblaCompassPhase: Equatable {
    case permissionRequired
    case locating
    case ready
    case permissionDenied
    case permissionRestricted
    case locationServicesDisabled
    case headingUnavailable
    case failed(String)
}

/// Owns the short-lived location and heading session used by `QiblaView`.
/// Coordinates and headings are deliberately never persisted or sent off-device.
@MainActor
final class QiblaCompassModel: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published private(set) var phase: QiblaCompassPhase
    @Published private(set) var qiblaBearing: CLLocationDirection?
    @Published private(set) var heading: CLLocationDirection?
    @Published private(set) var headingAccuracy: CLLocationDirection?
    @Published private(set) var isUsingTrueNorth = false
    @Published private(set) var needsCalibration = false

    private let manager: CLLocationManager
    private var isActive = false

    var signedTurn: Double? {
        guard let heading, let qiblaBearing else { return nil }
        return QiblaDirection.signedTurn(from: heading, to: qiblaBearing)
    }

    var isAligned: Bool {
        guard let signedTurn else { return false }
        return isUsingTrueNorth && abs(signedTurn) <= 3
    }

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.phase = Self.initialPhase(for: manager.authorizationStatus)
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 500
        manager.headingFilter = 1
        manager.headingOrientation = .portrait
        manager.activityType = .other
        manager.pausesLocationUpdatesAutomatically = true
    }

    func start() {
        isActive = true
        guard CLLocationManager.locationServicesEnabled() else {
            phase = .locationServicesDisabled
            return
        }
        continueForAuthorization(manager.authorizationStatus)
    }

    func requestPermission() {
        isActive = true
        guard CLLocationManager.locationServicesEnabled() else {
            phase = .locationServicesDisabled
            return
        }

        if manager.authorizationStatus == .notDetermined {
            phase = .locating
            manager.requestWhenInUseAuthorization()
        } else {
            continueForAuthorization(manager.authorizationStatus)
        }
    }

    func retry() {
        start()
    }

    func stop() {
        isActive = false
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    private func continueForAuthorization(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            phase = .permissionRequired
        case .authorizedAlways, .authorizedWhenInUse:
            beginUpdates()
        case .denied:
            phase = .permissionDenied
            stopUpdatesOnly()
        case .restricted:
            phase = .permissionRestricted
            stopUpdatesOnly()
        @unknown default:
            phase = .failed("Location authorization could not be determined.")
            stopUpdatesOnly()
        }
    }

    private func beginUpdates() {
        guard isActive else { return }

        phase = CLLocationManager.headingAvailable() ? .locating : .headingUnavailable
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    private func stopUpdatesOnly() {
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    private func markReadyIfPossible() {
        guard qiblaBearing != nil, heading != nil else { return }
        phase = .ready
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isActive else {
            phase = Self.initialPhase(for: manager.authorizationStatus)
            return
        }
        continueForAuthorization(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations
            .filter({ $0.horizontalAccuracy >= 0 && abs($0.timestamp.timeIntervalSinceNow) < 300 })
            .max(by: { $0.timestamp < $1.timestamp }) else { return }

        qiblaBearing = QiblaDirection.bearing(from: location.coordinate)
        if CLLocationManager.headingAvailable() {
            markReadyIfPossible()
        } else {
            phase = .headingUnavailable
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingAccuracy = newHeading.headingAccuracy >= 0 ? newHeading.headingAccuracy : nil
        needsCalibration = newHeading.headingAccuracy < 0 || newHeading.headingAccuracy > 25

        guard newHeading.headingAccuracy >= 0 else { return }

        let reportsTrueNorth = newHeading.trueHeading >= 0
        let measuredHeading = reportsTrueNorth ? newHeading.trueHeading : newHeading.magneticHeading
        isUsingTrueNorth = reportsTrueNorth

        if let previous = heading {
            let delta = QiblaDirection.signedTurn(from: previous, to: measuredHeading)
            heading = QiblaDirection.normalize(previous + delta * 0.22)
        } else {
            heading = QiblaDirection.normalize(measuredHeading)
        }
        markReadyIfPossible()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError {
            if locationError.code == .locationUnknown { return }
            if locationError.code == .denied {
                continueForAuthorization(manager.authorizationStatus)
                return
            }
        }

        guard qiblaBearing == nil else { return }
        phase = .failed("Your location could not be determined. Move to an open area and try again.")
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }

    private static func initialPhase(for status: CLAuthorizationStatus) -> QiblaCompassPhase {
        switch status {
        case .notDetermined: return .permissionRequired
        case .authorizedAlways, .authorizedWhenInUse: return .locating
        case .denied: return .permissionDenied
        case .restricted: return .permissionRestricted
        @unknown default: return .failed("Location authorization could not be determined.")
        }
    }
}
