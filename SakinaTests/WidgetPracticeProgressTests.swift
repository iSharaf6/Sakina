import XCTest
import UIKit
@testable import Sakina

final class WidgetPracticeProgressTests: XCTestCase {
    func testWidgetArtworkIsBoundedTransparentAndStillVisible() throws {
        for artwork in [CompanionArtwork.widgetMorning, .widgetEvening, .widgetReading] {
            let image = CompanionImage.image(artwork)
            let cg = try XCTUnwrap(image.cgImage, "Missing decoded widget artwork: \(artwork)")
            XCTAssertGreaterThan(cg.width, 0)
            XCTAssertGreaterThan(cg.height, 0)
            XCTAssertLessThanOrEqual(max(cg.width, cg.height), 420,
                                     "Widget artwork must be downsampled before allocating pixel buffers: \(artwork)")

            var pixels = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
            try pixels.withUnsafeMutableBytes { buffer in
                let context = try XCTUnwrap(CGContext(
                    data: buffer.baseAddress, width: cg.width, height: cg.height,
                    bitsPerComponent: 8, bytesPerRow: cg.width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
                ))
                context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            }
            let topRightAlpha = ((cg.height - 1) * cg.width + cg.width - 1) * 4 + 3
            XCTAssertEqual(pixels[topRightAlpha], 0, "White corner paper must be removed: \(artwork)")
            XCTAssertTrue(stride(from: 3, to: pixels.count, by: 4).contains { pixels[$0] > 200 },
                          "Removing white paper must not erase the illustration: \(artwork)")
        }
    }

    private func storage() -> UserDefaults {
        let name = "widget-practice-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    private func calendar(_ timeZone: String = "Australia/Sydney") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        return calendar
    }

    private func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

    func testMissingAndCorruptSnapshotsNeverClaimCompletion() {
        let defaults = storage()
        let now = date("2026-09-13T01:00:00Z")
        let empty = SharedStore.practiceProgress(on: now, calendar: calendar(), in: defaults)
        XCTAssertFalse(empty.morningComplete)
        XCTAssertFalse(empty.eveningComplete)
        XCTAssertEqual(empty.completedCount, 0)

        defaults.set(Data("not valid JSON".utf8), forKey: "widgetPracticeProgress.v1")
        XCTAssertEqual(SharedStore.practiceProgress(on: now, calendar: calendar(), in: defaults), empty)
    }

    func testStorageRoundTripPreservesIndependentCompletionsAndDeduplicatesWrites() {
        let defaults = storage()
        let now = date("2026-09-13T01:00:00Z")
        let morning = WidgetPracticeProgress(on: now, morningComplete: true, calendar: calendar())
        XCTAssertTrue(SharedStore.savePracticeProgress(morning, in: defaults))
        XCTAssertFalse(SharedStore.savePracticeProgress(morning, in: defaults))
        let restored = SharedStore.practiceProgress(on: now, calendar: calendar(), in: defaults)
        XCTAssertTrue(restored.morningComplete)
        XCTAssertFalse(restored.eveningComplete)
        XCTAssertEqual(restored.completedCount, 1)

        let both = WidgetPracticeProgress(on: now, morningComplete: true, eveningComplete: true, calendar: calendar())
        XCTAssertTrue(SharedStore.savePracticeProgress(both, in: defaults))
        XCTAssertEqual(SharedStore.practiceProgress(on: now, calendar: calendar(), in: defaults).completedCount, 2)
    }

    func testNextDayTimelineResetsCompletionAtLocalMidnight() {
        let defaults = storage()
        let beforeMidnight = date("2026-10-03T13:59:00Z") // Sydney, Oct 3 at 23:59, before DST.
        let afterMidnight = date("2026-10-03T14:01:00Z")  // Sydney, Oct 4 at 00:01.
        let progress = WidgetPracticeProgress(on: beforeMidnight, morningComplete: true,
                                              eveningComplete: true, calendar: calendar())
        SharedStore.savePracticeProgress(progress, in: defaults)
        XCTAssertEqual(SharedStore.practiceProgress(on: beforeMidnight, calendar: calendar(), in: defaults).completedCount, 2)
        XCTAssertEqual(SharedStore.practiceProgress(on: afterMidnight, calendar: calendar(), in: defaults).completedCount, 0)
        // DST starts later that night; adding a fixed 24 hours is not a day boundary.
        let afterDST = date("2026-10-03T16:01:00Z")
        XCTAssertEqual(SharedStore.practiceProgress(on: afterDST, calendar: calendar(), in: defaults).completedCount, 0)
    }

    func testProgressUsesGregorianLocalDateAcrossCalendarAndTimeZoneChanges() {
        let instant = date("2026-09-12T14:30:00Z")
        let progress = WidgetPracticeProgress(on: instant, morningComplete: true, calendar: calendar())
        XCTAssertEqual(WidgetPracticeProgress.dayKey(for: instant, calendar: calendar()), "2026-09-13")
        XCTAssertEqual(progress.current(on: instant, calendar: calendar("America/Los_Angeles")).completedCount, 0)

        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = calendar().timeZone
        XCTAssertEqual(WidgetPracticeProgress.dayKey(for: instant, calendar: hijri), "2026-09-13")
        XCTAssertTrue(progress.current(on: instant, calendar: hijri).morningComplete)
    }

    func testBookmarksAndGoalCheckboxesDoNotCountAsReadingCompletion() {
        let app = storage(), shared = storage()
        let now = date("2026-09-13T01:00:00Z")
        app.set(ReadingPlace.updating(.morning, entryID: DuaPractice.morning.entryIDs.last, in: ""), forKey: ReadingPlace.key)
        app.set(GoalLog.toggling("morning", on: now, in: ""), forKey: GoalLog.key)
        app.set(PracticeLog.marking(.sleep, on: now, calendar: calendar(), in: ""), forKey: PracticeLog.key)
        WidgetPracticeSync.refresh(on: now, calendar: calendar(), appDefaults: app, sharedDefaults: shared, reload: {})
        XCTAssertEqual(SharedStore.practiceProgress(on: now, calendar: calendar(), in: shared).completedCount, 0)
    }

    func testReaderCompletionAndLogClearingReloadOnlyWhenSharedProgressChanges() {
        let app = storage(), shared = storage()
        let now = date("2026-09-13T01:00:00Z")
        var reloadCount = 0
        func sync(_ date: Date) -> Bool {
            WidgetPracticeSync.refresh(on: date, calendar: calendar(), appDefaults: app,
                                       sharedDefaults: shared, reload: { reloadCount += 1 })
        }
        XCTAssertTrue(sync(now))
        XCTAssertFalse(sync(now))
        XCTAssertEqual(reloadCount, 1)
        app.set(PracticeLog.marking(.morning, on: now, calendar: calendar(), in: ""), forKey: PracticeLog.key)
        XCTAssertTrue(sync(now))
        XCTAssertTrue(SharedStore.practiceProgress(on: now, calendar: calendar(), in: shared).morningComplete)
        XCTAssertFalse(sync(now))
        XCTAssertEqual(reloadCount, 2)

        app.removeObject(forKey: PracticeLog.key)
        XCTAssertTrue(sync(now))
        XCTAssertEqual(SharedStore.practiceProgress(on: now, calendar: calendar(), in: shared).completedCount, 0)
        XCTAssertEqual(reloadCount, 3)

        let tomorrow = date("2026-09-14T01:00:00Z")
        XCTAssertTrue(sync(tomorrow))
        XCTAssertFalse(sync(tomorrow))
        XCTAssertEqual(reloadCount, 4)
    }
}
