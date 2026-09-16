import XCTest
@testable import Sakina

final class AdhkarChapterTests: XCTestCase {
    func testEveryExcerptBelongsToItsCollectionAndFitsTheRecording() throws {
        for recording in AdhkarRecording.allCases {
            let practice = try XCTUnwrap(DuaPractice(rawValue: recording.rawValue))
            let ids = recording.chapters.map(\.duaID)
            XCTAssertEqual(Set(ids).count, ids.count, "A dua must resolve to exactly one excerpt")
            for chapter in recording.chapters {
                XCTAssertTrue(practice.entryIDs.contains(chapter.duaID), chapter.duaID)
                XCTAssertNotNil(DuaCollection.dua(chapter.duaID))
                XCTAssertGreaterThan(chapter.end, chapter.start)
                XCTAssertGreaterThanOrEqual(chapter.start, 0)
                XCTAssertLessThanOrEqual(chapter.end, recording.duration)
                XCTAssertFalse(chapter.titleEnglish.isEmpty)
                XCTAssertFalse(chapter.titleArabic.isEmpty)
            }
        }
    }

    func testAnNasIsAvailableInBothRecordingsAndUnknownDuasHaveNoClip() throws {
        for recording in AdhkarRecording.allCases {
            let chapter = try XCTUnwrap(recording.chapter(for: "morning-surah-an-nas"))
            XCTAssertGreaterThan(chapter.end - chapter.start, 20)
            XCTAssertLessThan(chapter.end - chapter.start, 45)
            XCTAssertNil(recording.chapter(for: "not-an-adhkar-entry"))
        }
    }
}
