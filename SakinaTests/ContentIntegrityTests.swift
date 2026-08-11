import CryptoKit
import XCTest
@testable import Sakina

final class ContentIntegrityTests: XCTestCase {
    /// Update only after a fresh source comparison and a human review of the
    /// bundled Qur'an payload. This catches accidental glyph normalization.
    private let reviewedVersesSHA256 = "676b06ac73bb6dc657b47f96a9e225f85e43e0e6f34211b7a85f336022142d8c"

    func testEverySituationResolvesEveryVerse() {
        for situation in SituationCatalog.all {
            XCTAssertFalse(situation.verseKeys.isEmpty, "\(situation.id) has no ayah")
            XCTAssertEqual(
                situation.verses.count,
                situation.verseKeys.count,
                "\(situation.id) references an ayah missing from verses.json"
            )
        }
    }

    func testVerseKeysAndFieldsAgree() {
        let verses = VerseStore.shared.all
        XCTAssertEqual(Set(verses.map(\.key)).count, verses.count, "Verse keys must be unique")

        for verse in verses {
            XCTAssertEqual(verse.key, "\(verse.surah):\(verse.ayah)")
            XCTAssertFalse(verse.arabic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertFalse(verse.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertEqual(
                verse.audioFile,
                String(format: "%03d%03d", verse.surah, verse.ayah),
                "Audio filename disagrees with \(verse.key)"
            )
        }
    }

    func testEverySituationAppearsInTheNewGroupFlow() {
        let groupedIDs = GuidanceCatalog.groups
            .flatMap(\.stages)
            .flatMap(\.situationIDs)
        XCTAssertEqual(Set(groupedIDs), Set(SituationCatalog.all.map(\.id)))
        XCTAssertEqual(groupedIDs.count, Set(groupedIDs).count, "A situation appears in more than one stage")
    }

    func testEmergencyGuidancePromptsAreUniqueSearchableAndResolvable() {
        let prompts = EmergencyGuidanceCatalog.prompts
        XCTAssertFalse(prompts.isEmpty)

        let promptIDs = prompts.map(\.id)
        XCTAssertEqual(
            promptIDs.count,
            Set(promptIDs).count,
            "Emergency guidance prompt IDs must be unique"
        )

        let normalizedPhrases = prompts
            .flatMap(\.searchablePhrases)
            .map(normalizedPrompt)
        XCTAssertFalse(normalizedPhrases.contains(""), "Emergency guidance prompts cannot be blank")
        XCTAssertEqual(
            normalizedPhrases.count,
            Set(normalizedPhrases).count,
            "Emergency guidance prompts and aliases must not repeat"
        )

        for prompt in prompts {
            let situation = prompt.situation
            XCTAssertNotNil(situation, "\(prompt.id) targets an unknown situation")
            XCTAssertFalse(prompt.titleArabic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            for phrase in prompt.searchablePhrases {
                XCTAssertTrue(
                    GuidanceCatalog.search(phrase).contains { $0.id == prompt.situationID },
                    "\(prompt.id) is not searchable by: \(phrase)"
                )
            }
        }
    }

    func testEverySituationHasBilingualCompanionContent() {
        XCTAssertTrue(
            CompanionContentCatalog.uncoveredSituationIDs.isEmpty,
            "Missing companion content: \(CompanionContentCatalog.uncoveredSituationIDs.joined(separator: ", "))"
        )
        XCTAssertTrue(
            CompanionContentCatalog.validationIssues.isEmpty,
            CompanionContentCatalog.validationIssues.joined(separator: "\n")
        )

        for situation in SituationCatalog.all {
            XCTAssertNotEqual(situation.arabicTitle, situation.title, "\(situation.id) needs an Arabic title")
            let content = CompanionContentCatalog.content(for: situation)
            XCTAssertFalse(content.hadiths.isEmpty, "\(situation.id) has no hadith")
            XCTAssertFalse(content.supplications.isEmpty, "\(situation.id) has no du'a")
        }

        XCTAssertTrue(
            ArabicReflections.isComplete,
            "Missing Arabic reflections: \(ArabicReflections.missingSituationIDs.joined(separator: ", "))"
        )
    }

    func testReviewedQuranPayloadChecksum() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "verses", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(actual, reviewedVersesSHA256)
    }

    private func normalizedPrompt(_ value: String) -> String {
        let folded = value.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        let words = folded.unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? String($0) : " " }
            .joined()
            .split(whereSeparator: \.isWhitespace)
        return words.joined(separator: " ")
    }
}
