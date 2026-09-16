import XCTest
@testable import Sakina

final class AdhkarPlaybackRangeTests: XCTestCase {
    func testWholeRecordingUsesItsActualDuration() throws {
        let range = try XCTUnwrap(AdhkarPlaybackRange(sourceDuration: 1291.938))
        XCTAssertEqual(range.start, 0)
        XCTAssertEqual(range.end, 1291.938)
        XCTAssertEqual(range.duration, 1291.938)
    }

    func testExcerptConvertsRelativeScrubbingToSourceTime() throws {
        let range = try XCTUnwrap(AdhkarPlaybackRange(sourceDuration: 1200, start: 123.4, end: 164.9))
        XCTAssertEqual(range.duration, 41.5, accuracy: 0.001)
        XCTAssertEqual(range.sourceTime(for: 15), 138.4, accuracy: 0.001)
        XCTAssertEqual(range.relativeTime(for: 140.4), 17, accuracy: 0.001)
    }

    func testSeekingAndSkippingCannotLeaveTheSelectedDua() throws {
        let range = try XCTUnwrap(AdhkarPlaybackRange(sourceDuration: 1200, start: 300, end: 330))
        XCTAssertEqual(range.sourceTime(for: -15), 300)
        XCTAssertEqual(range.sourceTime(for: 500), 330)
        XCTAssertEqual(range.relativeTime(for: 299.9), 0)
        XCTAssertEqual(range.relativeTime(for: 900), 30)
    }

    func testExcerptEndCannotExceedAvailableAudio() throws {
        let range = try XCTUnwrap(AdhkarPlaybackRange(sourceDuration: 1200, start: 1170, end: 1500))
        XCTAssertEqual(range.end, 1200)
        XCTAssertEqual(range.duration, 30)
    }

    func testInvalidTimestampsCannotFallBackToPlayingAnotherDua() {
        XCTAssertNil(AdhkarPlaybackRange(sourceDuration: 1200, start: 400, end: 300))
        XCTAssertNil(AdhkarPlaybackRange(sourceDuration: 1200, start: 300, end: 300))
        XCTAssertNil(AdhkarPlaybackRange(sourceDuration: 1200, start: 1200))
        XCTAssertNil(AdhkarPlaybackRange(sourceDuration: 1200, start: .infinity))
        XCTAssertNil(AdhkarPlaybackRange(sourceDuration: 1200, end: .nan))
        for duration in [0, -1, .nan, .infinity] {
            XCTAssertNil(AdhkarPlaybackRange(sourceDuration: duration))
        }
    }

    func testNonFinitePlaybackProgressNeverReachesTheUI() throws {
        let range = try XCTUnwrap(AdhkarPlaybackRange(sourceDuration: 1200, start: 300, end: 330))
        XCTAssertEqual(range.sourceTime(for: .nan), 300)
        XCTAssertEqual(range.relativeTime(for: .infinity), 0)
    }
}
