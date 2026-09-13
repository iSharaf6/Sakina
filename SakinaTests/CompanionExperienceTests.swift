import XCTest
import UIKit
@testable import Sakina

final class CompanionExperienceTests: XCTestCase {
    func testArabicCountsUseGrammaticalFormsAtPluralBoundaries() {
        func duas(_ count: Int) -> String {
            ArabicCount.label(count, zero: "لا أدعية", one: "دعاء واحد", two: "دعاءان",
                              few: "أدعية", many: "دعاءً", other: "دعاء")
        }
        for (count, expected) in [(0, "لا أدعية"), (1, "دعاء واحد"), (2, "دعاءان"),
                                  (3, "٣ أدعية"), (10, "١٠ أدعية"), (11, "١١ دعاءً"),
                                  (33, "٣٣ دعاءً"), (99, "٩٩ دعاءً"), (100, "١٠٠ دعاء"),
                                  (103, "١٠٣ أدعية"), (111, "١١١ دعاءً")] {
            XCTAssertEqual(duas(count), expected, "Incorrect Arabic count for \(count)")
        }
    }

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
        for art in [CompanionArtwork.breathe, .settings, .saved, .appearance, .kaaba] {
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

final class PrayerScheduleDayTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        return calendar
    }

    private func date(_ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private func schedule(lateIsha: Bool = false) -> PrayerSchedule {
        let days = (13...14).map { day in
            PrayerDaySchedule(dayStart: date(day), events: [
                PrayerEvent(kind: .fajr, time: date(day, 4, day == 13 ? 35 : 34)),
                PrayerEvent(kind: .sunrise, time: date(day, 5, 58)),
                PrayerEvent(kind: .dhuhr, time: date(day, 11, 52)),
                PrayerEvent(kind: .asr, time: date(day, 15, 13)),
                PrayerEvent(kind: .maghrib, time: date(day, 17, 45)),
                PrayerEvent(kind: .isha, time: lateIsha ? date(day + 1, 0, 30) : date(day, 19, 3)),
            ])
        }
        return PrayerSchedule(generatedAt: date(13), expiresAt: date(16), locationLabel: "Sydney",
                              timeZoneIdentifier: calendar.timeZone.identifier,
                              calculationMethodID: "muslimWorldLeague", asrMethodID: "standard", days: days)
    }

    func testDaytimeScheduleKeepsTodayAndHighlightsTheActualNextEvent() {
        let schedule = schedule()
        let now = date(13, 10)
        let day = schedule.upcomingDay(after: now)
        XCTAssertEqual(day?.dayStart, date(13))
        XCTAssertEqual(schedule.nextEvent(after: now)?.kind, .dhuhr)
        XCTAssertEqual(day?.events.filter { $0 == schedule.nextEvent(after: now) }.count, 1)
    }

    func testAfterIshaDisplaysTomorrowsFajrRatherThanTodaysSameNamedPrayer() {
        let schedule = schedule()
        let now = date(13, 20)
        let day = schedule.upcomingDay(after: now)
        let next = schedule.nextEvent(after: now)
        XCTAssertEqual(day?.dayStart, date(14))
        XCTAssertEqual(next?.time, date(14, 4, 34))
        XCTAssertEqual(day?.time(for: .fajr), next?.time)
        XCTAssertFalse(schedule.events(on: now).contains { $0 == next })
        XCTAssertEqual(day?.events.filter { $0 == next }.count, 1)
    }

    func testLocationMidnightUsesTheNextLocalDayEvenWhenUTCIsStillYesterday() {
        let schedule = schedule()
        let now = date(14, 1)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(utc.component(.day, from: now), 13)
        XCTAssertEqual(schedule.upcomingDay(after: now)?.dayStart, date(14))
        XCTAssertEqual(schedule.upcomingDay(after: now)?.time(for: .fajr), date(14, 4, 34))
    }

    func testIshaAfterMidnightStaysWithItsCalculationDay() {
        let schedule = schedule(lateIsha: true)
        let now = date(14, 0, 10)
        let next = schedule.nextEvent(after: now)
        XCTAssertEqual(next?.kind, .isha)
        XCTAssertEqual(next?.time, date(14, 0, 30))
        XCTAssertEqual(schedule.upcomingDay(after: now)?.dayStart, date(13))
        XCTAssertTrue(schedule.upcomingDay(after: now)?.events.contains { $0 == next } == true)
        XCTAssertFalse(schedule.events(on: now).contains { $0 == next })
    }

    func testExhaustedScheduleDoesNotReuseAnOldPrayerDay() {
        let schedule = schedule()
        XCTAssertNil(schedule.upcomingDay(after: date(15, 12)))
    }
}
