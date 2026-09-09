import UIKit
import XCTest
@testable import Sakina

final class DuaCollectionTests: XCTestCase {
    func testEveryMoodResolvesReviewedContentWithoutDuplicates() {
        for mood in DuaMood.allCases {
            let entries = DuaCollection.entries(mood: mood)
            XCTAssertEqual(entries.count, mood.supplicationIDs.count, "Unresolved du’a in \(mood)")
            XCTAssertGreaterThanOrEqual(entries.count, 3, "Too few readings for \(mood)")
            XCTAssertEqual(Set(entries.map(\.id)).count, entries.count)
            for entry in entries {
                XCTAssertTrue(DuaCollection.allEntries.contains(entry))
                XCTAssertTrue(entry.source.canonicalURL.hasPrefix("https://"))
                XCTAssertFalse(entry.arabic.isEmpty)
            }
            XCTAssertFalse(mood.opening(.english).isEmpty)
            XCTAssertFalse(mood.opening(.arabic).isEmpty)
        }
    }

    func testSearchSupportsArabicEnglishAndCanonicalReferences() {
        XCTAssertTrue(DuaCollection.entries(query: "28:24").contains { $0.id == "quran-need-any-good" })
        XCTAssertTrue(DuaCollection.entries(query: "gratitude").contains { $0.id == "quran-gratitude-and-good-deeds" })
        XCTAssertFalse(DuaCollection.entries(query: "الهداية").isEmpty)
        XCTAssertTrue(Set(DuaCollection.entries(query: "anxious").map(\.id)).isSuperset(of: Set(DuaMood.anxious.supplicationIDs)))
        XCTAssertFalse(DuaCollection.entries(query: "وحيد").isEmpty)
        XCTAssertTrue(DuaCollection.entries(query: "nonexistent-phrase-12345").isEmpty)
        XCTAssertEqual(DuaCollection.entries(query: "   ").count, DuaCollection.allEntries.count)
    }

    func testAllRequestedFeelingsAreDiscoverableExactlyOnce() {
        let required: Set<DuaMood> = [.angry, .anxious, .urgeToSin, .confident, .confused, .content, .depressed, .doubtful, .grateful, .greedy, .guilty, .happy, .hurt, .indecisive, .hypocritical, .jealous, .lazy, .lonely, .lost, .nervous, .overwhelmed, .regret, .sad, .scared, .suicidal, .tired, .unloved, .weak, .bored, .impatient]
        let grouped = FeelingFamily.allCases.flatMap(\.moods)
        XCTAssertTrue(required.isSubset(of: Set(grouped)))
        XCTAssertEqual(Set(grouped).count, grouped.count)
        for mood in required { XCTAssertFalse(DuaCollection.entries(query: mood.title(.english)).isEmpty, mood.rawValue) }
    }

    func testEveryPracticeResolvesDistinctSourcedReadings() {
        XCTAssertEqual(DuaPractice.allCases.count, 15)
        XCTAssertEqual(Set(DuaCollection.allEntries.map(\.id)).count, DuaCollection.allEntries.count)
        for practice in DuaPractice.allCases where practice != .names {
            XCTAssertGreaterThanOrEqual(practice.entries.count, 5, practice.rawValue)
            XCTAssertEqual(practice.entries.count, practice.entryIDs.count, practice.rawValue)
            XCTAssertEqual(Set(practice.entryIDs).count, practice.entries.count, practice.rawValue)
        }
        for entry in DuaLibrary.entries {
            XCTAssertFalse(entry.arabic.isEmpty, entry.id)
            XCTAssertFalse(entry.transliteration.isEmpty, entry.id)
            XCTAssertFalse(entry.meaning(.english).isEmpty, entry.id)
            XCTAssertFalse(entry.meaning(.arabic).isEmpty, entry.id)
            XCTAssertFalse(entry.context(.english).isEmpty, entry.id)
            XCTAssertFalse(entry.context(.arabic).isEmpty, entry.id)
            XCTAssertTrue(["sunnah.com", "quran.com"].contains(URL(string: entry.source.canonicalURL)?.host ?? ""), entry.id)
            XCTAssertFalse(entry.arabic.contains { $0.isLetter && $0.isASCII }, "Latin characters in Arabic of \(entry.id)")
            if let count = entry.repeatCount { XCTAssertGreaterThan(count, 1, entry.id) }
        }
        XCTAssertTrue(DuaPractice.quran.entries.allSatisfy { $0.source.kind == .quran })
        XCTAssertTrue(DuaPractice.sunnah.entries.allSatisfy { $0.source.kind == .hadith })
        XCTAssertTrue(DuaPractice.healing.entries.allSatisfy { $0.caution(.english) != nil }, "Healing readings should carry the medical-care note")
    }

    func testReadingPlaceResumesAndCompletesWithoutCrossCollectionLeakage() {
        let morning = DuaPractice.morning.entryIDs[0]
        let evening = DuaPractice.evening.entryIDs[0]
        let raw = ReadingPlace.updating(.morning, entryID: morning, in: "broken|evil=unknown|morning=removed")
        XCTAssertEqual(ReadingPlace.entry(for: .morning, in: raw), morning)
        let two = ReadingPlace.updating(.evening, entryID: evening, in: raw)
        XCTAssertEqual(ReadingPlace.entry(for: .morning, in: two), morning)
        let completed = ReadingPlace.updating(.morning, entryID: nil, in: two)
        XCTAssertNil(ReadingPlace.entry(for: .morning, in: completed))
        XCTAssertEqual(ReadingPlace.entry(for: .evening, in: completed), evening)
        XCTAssertNil(ReadingPlace.entry(for: .sleep, in: "sleep=\(morning)"))
    }

    func testPracticeLogAndHeartLogStayScopedToTheDay() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let raw = PracticeLog.marking(.morning, on: yesterday, in: "")
        XCTAssertTrue(PracticeLog.isDone(.morning, on: yesterday, in: raw))
        XCTAssertFalse(PracticeLog.isDone(.morning, on: today, in: raw))
        let rolled = PracticeLog.marking(.evening, on: today, in: raw)
        XCTAssertTrue(PracticeLog.isDone(.evening, on: today, in: rolled))
        XCTAssertFalse(PracticeLog.isDone(.morning, on: yesterday, in: rolled), "Older days are dropped")

        let log = HeartLog.recording(.anxious, on: yesterday, in: "")
        let log2 = HeartLog.recording(.grateful, on: today, in: log)
        let week = HeartLog.week(from: log2, ending: today)
        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(week.last?.mood, .grateful)
        XCTAssertEqual(week[5].mood, .anxious)
        XCTAssertEqual(HeartLog.suggestions(from: log2).prefix(2).map { $0 }, [.grateful, .anxious])
        XCTAssertEqual(HeartLog.suggestions(from: log2).count, 6)
        XCTAssertEqual(Set(HeartLog.suggestions(from: log2)).count, 6)
    }

    func testNinetyNineNamesAreCompleteAndUnique() {
        XCTAssertEqual(DivineName.all.count, 99)
        XCTAssertEqual(Set(DivineName.all.map(\.id)).count, 99)
        XCTAssertEqual(DivineName.all.first?.transliteration, "Ar-Rahman")
        XCTAssertEqual(DivineName.all.last?.transliteration, "As-Sabur")
        for name in DivineName.all {
            XCTAssertFalse(name.arabic.isEmpty)
            XCTAssertFalse(name.meaning(.english).isEmpty)
            XCTAssertFalse(name.meaning(.arabic).isEmpty)
            XCTAssertNotNil(name.reflection(.english))
            XCTAssertNotNil(name.reflection(.arabic))
            if !name.verse.isEmpty { XCTAssertNotNil(name.verse.range(of: #"^\d{1,3}:\d{1,3}$"#, options: .regularExpression), name.verse) }
        }
    }

    func testEverySymbolExistsInSFSymbols() {
        var symbols = DuaMood.allCases.map(\.symbol) + DuaPractice.allCases.map(\.symbol)
        symbols += FeelingFamily.allCases.map(\.symbol) + GuidanceCatalog.groups.map(\.badgeSymbol)
        symbols += ["house", "house.fill", "square.grid.2x2", "square.grid.2x2.fill", "text.book.closed", "text.book.closed.fill", "bookmark", "bookmark.fill",
                    "gearshape.fill", "quote.opening", "book.pages.fill", "location.north.circle.fill", "wind", "textformat.size", "lifepreserver", "phone.fill"]
        for symbol in symbols {
            XCTAssertNotNil(UIImage(systemName: symbol), "Missing SF Symbol \(symbol)")
        }
    }

    func testFavoriteRoundTripAndInvalidStoredIDs() {
        let first = "quran-need-any-good"
        let second = "quran-guidance"
        let once = DuaCollection.toggling(first, in: "")
        XCTAssertEqual(DuaCollection.savedIDs(once), [first])
        let twice = DuaCollection.toggling(second, in: once)
        XCTAssertEqual(DuaCollection.savedIDs(twice), [second, first])
        XCTAssertEqual(DuaCollection.savedIDs(DuaCollection.toggling(first, in: twice)), [second])
        XCTAssertEqual(DuaCollection.savedIDs("unknown|\(first)|\(first)||"), [first])
        XCTAssertEqual(DuaCollection.toggling("unknown", in: twice), twice)
    }

    func testFavoriteMoodAndSearchFiltersIntersect() {
        let saved = ["quran-need-any-good", "quran-guidance"]
        let hopefulSaved = DuaCollection.entries(mood: .hopeful, savedOnly: true, savedIDs: saved).map(\.id)
        XCTAssertTrue(Set(hopefulSaved).isSubset(of: Set(saved)))
        XCTAssertTrue(DuaCollection.entries(mood: .angry, query: "zzzz-no-match", savedOnly: true, savedIDs: saved).isEmpty)
        XCTAssertTrue(DuaCollection.entries(savedOnly: true, savedIDs: []).isEmpty)
    }
}
