import CoreLocation
import XCTest
@testable import Sakina

final class QiblaDirectionTests: XCTestCase {
    func testSydneyBearingPointsWestNorthwest() {
        let sydney = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
        XCTAssertEqual(QiblaDirection.bearing(from: sydney), 277.50, accuracy: 0.1)
    }

    func testSignedTurnUsesShortestDirectionAcrossNorth() {
        XCTAssertEqual(QiblaDirection.signedTurn(from: 350, to: 10), 20, accuracy: 0.001)
        XCTAssertEqual(QiblaDirection.signedTurn(from: 10, to: 350), -20, accuracy: 0.001)
    }

    func testNormalizesNegativeBearings() {
        XCTAssertEqual(QiblaDirection.normalize(-15), 345, accuracy: 0.001)
    }
}
