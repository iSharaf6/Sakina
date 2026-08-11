import CoreLocation
import Foundation

/// Pure, testable Qibla geometry. Bearings are clockwise from true north.
enum QiblaDirection {
    static let kaabaCoordinate = CLLocationCoordinate2D(
        latitude: 21.422487,
        longitude: 39.826206
    )

    static func bearing(from coordinate: CLLocationCoordinate2D) -> CLLocationDirection {
        let originLatitude = coordinate.latitude.radians
        let destinationLatitude = kaabaCoordinate.latitude.radians
        let longitudeDelta = (kaabaCoordinate.longitude - coordinate.longitude).radians

        let y = sin(longitudeDelta) * cos(destinationLatitude)
        let x = cos(originLatitude) * sin(destinationLatitude)
            - sin(originLatitude) * cos(destinationLatitude) * cos(longitudeDelta)

        return normalize(atan2(y, x).degrees)
    }

    /// The signed, shortest clockwise turn from one bearing to another.
    /// Positive values mean turn right; negative values mean turn left.
    static func signedTurn(from current: CLLocationDirection, to target: CLLocationDirection) -> Double {
        var difference = normalize(target) - normalize(current)
        if difference > 180 { difference -= 360 }
        if difference < -180 { difference += 360 }
        return difference
    }

    static func normalize(_ degrees: CLLocationDirection) -> CLLocationDirection {
        let remainder = degrees.truncatingRemainder(dividingBy: 360)
        return remainder >= 0 ? remainder : remainder + 360
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}
