import XCTest
@testable import Sakina

@MainActor
final class ReviewPromptPolicyTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func storage() -> UserDefaults {
        let name = "review-policy-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    private func day(_ offset: Int) -> Date {
        start.addingTimeInterval(Double(offset) * 86_400)
    }

    private func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func engage(_ policy: ReviewPromptPolicy, startingAt offset: Int = 0) {
        for n in 0..<5 {
            policy.recordCompletion(id: "morning", on: day(offset + n * 2))
        }
    }

    func testLaunchAndRepeatedCompletionOnOneDayNeverQualify() {
        let policy = ReviewPromptPolicy(defaults: storage(), calendar: calendar())
        XCTAssertFalse(policy.isEligible(version: "1.0", on: day(0)))
        for n in 0..<20 {
            policy.recordCompletion(id: "session-\(n)", on: day(0))
        }
        XCTAssertFalse(policy.isEligible(version: "1.0", on: day(10)))
    }

    func testEarlyHeavyUseStillWaitsOneWeek() {
        let policy = ReviewPromptPolicy(defaults: storage(), calendar: calendar())
        for n in 0..<5 {
            policy.recordCompletion(id: "morning", on: day(n))
        }
        XCTAssertFalse(policy.isEligible(version: "1.0", on: day(6)))
        XCTAssertTrue(policy.isEligible(version: "1.0", on: day(7)))
    }

    func testReopeningTheSameCompletionDoesNotAcceleratePrompt() {
        let policy = ReviewPromptPolicy(defaults: storage(), calendar: calendar())
        for offset in [0, 4, 8] {
            for _ in 0..<10 {
                policy.recordCompletion(id: "morning", on: day(offset))
            }
        }
        XCTAssertFalse(policy.isEligible(version: "1.0", on: day(8)))
        policy.recordCompletion(id: "evening", on: day(8))
        policy.recordCompletion(id: "morning", on: day(9))
        XCTAssertTrue(policy.isEligible(version: "1.0", on: day(9)))
    }

    func testPromptRequiresNewVersionCooldownAndAdditionalUse() {
        let policy = ReviewPromptPolicy(defaults: storage(), calendar: calendar())
        engage(policy)
        XCTAssertTrue(policy.isEligible(version: "1.0", on: day(8)))
        policy.recordRequest(version: "1.0", on: day(8))
        XCTAssertFalse(policy.isEligible(version: "1.1", on: day(128)))
        engage(policy, startingAt: 120)
        XCTAssertFalse(policy.isEligible(version: "1.1", on: day(127)))
        XCTAssertFalse(policy.isEligible(version: "1.0", on: day(128)))
        XCTAssertTrue(policy.isEligible(version: "1.1", on: day(128)))
    }

    func testThreeAttemptsPerRollingYearEvenAcrossNewVersions() {
        let policy = ReviewPromptPolicy(defaults: storage(), calendar: calendar())
        for (index, offset) in [0, 120, 240].enumerated() {
            engage(policy, startingAt: offset)
            let version = "1.\(index)"
            XCTAssertTrue(policy.isEligible(version: version, on: day(offset + 8)))
            policy.recordRequest(version: version, on: day(offset + 8))
        }
        engage(policy, startingAt: 360)
        XCTAssertFalse(policy.isEligible(version: "2.0", on: day(368)))
        XCTAssertTrue(policy.isEligible(version: "2.0", on: day(374)))
    }

    func testTimingAndPromptAttemptsSurviveRelaunch() {
        let defaults = storage()
        let original = ReviewPromptPolicy(defaults: defaults, calendar: calendar())
        engage(original)
        let restored = ReviewPromptPolicy(defaults: defaults, calendar: calendar())
        XCTAssertTrue(restored.isEligible(version: "1.0", on: day(8)))
        restored.recordRequest(version: "1.0", on: day(8))
        let afterPrompt = ReviewPromptPolicy(defaults: defaults, calendar: calendar())
        XCTAssertFalse(afterPrompt.isEligible(version: "1.0", on: day(8)))
        XCTAssertFalse(afterPrompt.isEligible(version: "1.1", on: day(130)))
    }

    func testDamagedStorageRestartsWithoutAnImmediatePrompt() {
        let defaults = storage()
        defaults.set(Data("invalid".utf8), forKey: ReviewPromptPolicy.storageKey)
        let policy = ReviewPromptPolicy(defaults: defaults, calendar: calendar())
        XCTAssertFalse(policy.isEligible(version: "1.0", on: day(8)))
    }
}
