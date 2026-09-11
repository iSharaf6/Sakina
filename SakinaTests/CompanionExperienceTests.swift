import XCTest
import UIKit
@testable import Sakina

final class CompanionExperienceTests: XCTestCase {
    private func defaults() -> UserDefaults {
        let name = "companion-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    func testEmailValidationRejectsMalformedAndAcceptsTrimmedAddresses() {
        for email in ["", "person", "person@", "@example.com", "person@example", "a b@example.com"] {
            XCTAssertFalse(CompanionAccount.validEmail(email), email)
        }
        XCTAssertTrue(CompanionAccount.validEmail("  person+reading@example.com\n"))
    }

    func testNoNotificationsWithoutOptIn() {
        XCTAssertTrue(CompanionReminderPlan.make(defaults: defaults(), schedule: .placeholder()).isEmpty)
    }

    func testPrayerAlertsUseAbsoluteDatesAndNeverNotifyForSunrise() {
        let d = defaults(); d.set(true, forKey: CompanionReminderPlan.prayerKey)
        let schedule = PrayerSchedule.placeholder()
        let now = schedule.days[0].dayStart
        let items = CompanionReminderPlan.make(defaults: d, schedule: schedule, now: now)
        let expected = schedule.allEvents.filter { $0.kind != .sunrise && $0.time > now && $0.time < schedule.expiresAt }
        XCTAssertEqual(items.count, expected.count)
        XCTAssertFalse(items.isEmpty)
        XCTAssertTrue(items.allSatisfy { !$0.repeats && $0.components.year != nil && $0.components.timeZone?.secondsFromGMT() == 0 })
        XCTAssertEqual(Set(items.map(\.id)).count, items.count)
        XCTAssertTrue(items.allSatisfy { $0.destination == "haneen://prayer-times" })
    }

    func testQuietHoursHandleMidnightAndDisabledInterval() {
        XCTAssertTrue(CompanionReminderPlan.isQuiet(23, start: 22, end: 7))
        XCTAssertTrue(CompanionReminderPlan.isQuiet(6, start: 22, end: 7))
        XCTAssertFalse(CompanionReminderPlan.isQuiet(12, start: 22, end: 7))
        XCTAssertFalse(CompanionReminderPlan.isQuiet(9, start: 9, end: 9))
        XCTAssertTrue(CompanionReminderPlan.isQuiet(13, start: 12, end: 14))
    }

    func testDailyReflectionMovesToQuietHoursEndAndBudgetRemainsAvailable() {
        let d = defaults()
        for key in [SettingsKeys.reminderEnabled, CompanionReminderPlan.prayerKey, CompanionReminderPlan.morningKey, CompanionReminderPlan.eveningKey] { d.set(true, forKey: key) }
        d.set(23, forKey: SettingsKeys.reminderHour)
        let schedule = PrayerSchedule.placeholder()
        let items = CompanionReminderPlan.make(defaults: d, schedule: schedule, now: schedule.days[0].dayStart)
        let daily = items.filter { $0.id.hasPrefix("yaqeen.guidance.") }
        XCTAssertEqual(daily.count, 7)
        XCTAssertTrue(daily.allSatisfy { $0.components.hour == 7 && $0.repeats })
        XCTAssertLessThanOrEqual(items.count, 60)
        XCTAssertEqual(Set(items.map(\.id)).count, items.count)
    }

    func testExpiredScheduleDoesNotSendStalePrayerAlerts() {
        let d = defaults(); d.set(true, forKey: CompanionReminderPlan.prayerKey)
        let schedule = PrayerSchedule.placeholder()
        XCTAssertTrue(CompanionReminderPlan.make(defaults: d, schedule: schedule, now: schedule.expiresAt).isEmpty)
    }

    func testResetPreservesLibraryAccountAndOnboarding() {
        let d = defaults()
        for key in SettingsReset.keys { d.set("changed", forKey: key) }
        let preserved = ["yaqeen.library.v1", "auth.session", CompanionOnboarding.completedKey, "prayer.localCalculationLocation"]
        for key in preserved { d.set("keep", forKey: key) }
        SettingsReset.reset(d)
        XCTAssertTrue(SettingsReset.keys.allSatisfy { d.object(forKey: $0) == nil })
        for key in preserved { XCTAssertEqual(d.string(forKey: key), "keep") }
    }

    func testTenDistinctWidgetChoicesHaveValidDestinationsAndArtwork() {
        XCTAssertEqual(CompanionWidgetChoice.allCases.count, 10)
        XCTAssertEqual(Set(CompanionWidgetChoice.allCases.map(\.title)).count, 10)
        for choice in CompanionWidgetChoice.allCases {
            XCTAssertEqual(choice.destination.scheme, "haneen")
            XCTAssertNotNil(UIImage(named: choice.artwork.assetName), choice.rawValue)
        }
    }

    func testArtworkRenderingRemovesEdgePaperAndKeepsVisibleContent() {
        for art in [CompanionArtwork.breathe, .settings, .saved, .appearance] {
            let image = CompanionImage.image(art)
            guard let cg = image.cgImage else { return XCTFail("Missing \(art)") }
            var pixels = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
            let context = CGContext(data: &pixels, width: cg.width, height: cg.height, bitsPerComponent: 8,
                                   bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            XCTAssertEqual(pixels[3], 0, "Paper remains at corner for \(art)")
            if let mask = CompanionImage.inkMask(art).cgImage {
                context.clear(CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
                context.draw(mask, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
                XCTAssertEqual(pixels[3], 0, "Lock Screen mask retains paper for \(art)")
                context.clear(CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
                context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            }
            let opaque = stride(from: 3, to: pixels.count, by: 4).filter { pixels[$0] > 200 }.count
            XCTAssertGreaterThan(opaque, cg.width * cg.height / 10, "Illustration disappeared for \(art)")
        }
    }
}
