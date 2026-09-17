import XCTest
@testable import Sakina

@MainActor
final class AccountHubContentTests: XCTestCase {
    func testLibraryCountsDistinctOpenableContentAndKeepsOrphanReflections() throws {
        var annotated = AyahMark(key: "1:1")
        annotated.bookmarked = true
        annotated.highlight = .green
        annotated.note = "A reflection on this ayah"
        var duplicate = annotated
        duplicate.favourite = true
        var whitespace = AyahMark(key: "1:2")
        whitespace.note = " \n "
        var stale = AyahMark(key: "999:999")
        stale.bookmarked = true
        stale.note = "A removed reference"
        let duaID = try XCTUnwrap(DuaCollection.allEntries.first?.id)
        let situationID = try XCTUnwrap(SituationCatalog.all.first?.id)

        let summary = AccountLibrarySummary(
            marks: [annotated, duplicate, whitespace, stale],
            savedDuas: "\(duaID)|removed-dua|\(duaID)",
            situationIDs: [situationID, situationID, "removed-situation"],
            reflectionTexts: ["Saved words, even if the original reading is gone", " \n "]
        )

        XCTAssertEqual(summary.ayat, 1, "Multiple marks on the same ayah are one library item")
        XCTAssertEqual(summary.notes, 1)
        XCTAssertEqual(summary.duas, 1, "Stale saved IDs must not inflate a destination's count")
        XCTAssertEqual(summary.moments, 1)
        XCTAssertEqual(summary.reflections, 1, "Written reflections do not depend on a surviving catalog reference")
    }

    func testContinueReadingRequiresAValidSavedAyah() {
        XCTAssertNil(AccountLibrarySummary.readingAyah(for: nil))
        XCTAssertNil(AccountLibrarySummary.readingAyah(for: ""))
        XCTAssertNil(AccountLibrarySummary.readingAyah(for: "999:999"))
        XCTAssertEqual(AccountLibrarySummary.readingAyah(for: "2:255")?.key, "2:255")
    }

    func testRoutineCountsOnlyChosenGoalsAndRollsOverToNewDay() throws {
        let today = Date(timeIntervalSince1970: 1_780_000_000)
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))
        let morningDone = GoalLog.toggling("morning", on: today, in: "")
        let includesDisabled = GoalLog.toggling("sleep", on: today, in: morningDone)
        let summary = AccountRoutineSummary(enabledRaw: "morning|quran", logRaw: includesDisabled, on: today)
        XCTAssertEqual(summary.completed, 1)
        XCTAssertEqual(summary.progress, 0.5)
        XCTAssertEqual(summary.nextGoal?.id, "quran")

        let newDay = AccountRoutineSummary(enabledRaw: "morning|quran", logRaw: includesDisabled, on: tomorrow)
        XCTAssertEqual(newDay.completed, 0)
        XCTAssertEqual(newDay.progress, 0)
        XCTAssertEqual(newDay.nextGoal?.id, "morning")

        let noGoals = AccountRoutineSummary(enabledRaw: GoalPreferences.none, logRaw: includesDisabled, on: today)
        XCTAssertTrue(noGoals.enabled.isEmpty)
        XCTAssertEqual(noGoals.completed, 0)
        XCTAssertEqual(noGoals.progress, 0)
        XCTAssertNil(noGoals.nextGoal)
    }
}
