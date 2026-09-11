import XCTest
@testable import Sakina

final class DuaRewardTests: XCTestCase {
    func testAllVirtuesResolveToRealEntriesAndHaveBilingualSourcesAndConditions() {
        XCTAssertGreaterThanOrEqual(DuaRewardCatalog.all.count, 30)
        let ids = DuaRewardCatalog.all.flatMap(\.entryIDs)
        XCTAssertEqual(ids.count, Set(ids).count)
        for reward in DuaRewardCatalog.all {
            for id in reward.entryIDs { XCTAssertNotNil(DuaCollection.dua(id), id) }
            XCTAssertEqual(URL(string: reward.sourceURL)?.scheme, "https")
            for language in AppLanguage.allCases {
                XCTAssertFalse(reward.summary(language).isEmpty)
                XCTAssertFalse(reward.conditions(language).isEmpty)
                XCTAssertFalse(reward.source(language).isEmpty)
                XCTAssertFalse(reward.grade(language).isEmpty)
            }
        }
    }

    func testQuranRecitationVirtuesCiteTheHadithAndKeepFullPassageConditions() throws {
        let quls = try XCTUnwrap(DuaRewardCatalog.reward(for: "morning-surah-al-ikhlas"))
        XCTAssertEqual(quls.sourceURL, "https://sunnah.com/abudawud:5082")
        XCTAssertTrue(quls.conditionsEnglish.contains("three times each"))
        XCTAssertTrue(quls.conditionsEnglish.contains("all three"))
        let baqarah = try XCTUnwrap(DuaRewardCatalog.reward(for: "ruqyah-quran-2-1-5"))
        XCTAssertTrue(baqarah.conditionsEnglish.contains("as a whole"))
        XCTAssertNil(DuaRewardCatalog.reward(for: "daily-waking"), "Do not invent a reward from the wording alone")
    }

    func testMorningAndBedtimeKursiHaveDifferentEvidence() throws {
        let morning = try XCTUnwrap(DuaRewardCatalog.reward(for: "morning-ayat-al-kursi"))
        let bedtime = try XCTUnwrap(DuaRewardCatalog.reward(for: "sleep-ayat-al-kursi"))
        XCTAssertNotEqual(morning.sourceURL, bedtime.sourceURL)
        XCTAssertTrue(morning.conditionsEnglish.contains("morning and evening"))
        XCTAssertTrue(bedtime.conditionsEnglish.contains("bedtime"))
    }
}
