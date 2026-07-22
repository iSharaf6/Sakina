import CryptoKit
import UIKit
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

    func testEveryLifeGroupHasUniqueBundledArtwork() throws {
        let groups = GuidanceCatalog.groups
        let assetNames = groups.map(\.id.artworkAssetName)

        XCTAssertEqual(Set(groups.map(\.id)), Set(LifeGroupID.allCases))
        XCTAssertEqual(assetNames.count, Set(assetNames).count, "Life-group artwork names must be unique")

        for assetName in assetNames {
            let image = try XCTUnwrap(UIImage(named: assetName), "Missing bundled artwork: \(assetName)")
            let pixels = try XCTUnwrap(image.cgImage, "Artwork is not a raster image: \(assetName)")
            XCTAssertEqual(pixels.width, 512, "\(assetName) must be 512 px wide")
            XCTAssertEqual(pixels.height, 512, "\(assetName) must be 512 px high")
            try assertArtworkHasTransparentBackground(image, assetName: assetName)
        }
    }

    func testEveryOnboardingHeroHasUniqueBundledArtwork() throws {
        let assetNames = OnboardingHeroArt.allCases.map(\.rawValue)

        XCTAssertEqual(
            Set(assetNames),
            Set(["OnboardingPrayer", "OnboardingReminder", "OnboardingReading"])
        )
        XCTAssertEqual(assetNames.count, Set(assetNames).count, "Onboarding artwork names must be unique")

        for assetName in assetNames {
            let image = try XCTUnwrap(UIImage(named: assetName), "Missing bundled artwork: \(assetName)")
            let pixels = try XCTUnwrap(image.cgImage, "Artwork is not a raster image: \(assetName)")
            XCTAssertEqual(pixels.width, 512, "\(assetName) must be 512 px wide")
            XCTAssertEqual(pixels.height, 512, "\(assetName) must be 512 px high")
            try assertArtworkHasTransparentBackground(image, assetName: assetName)
        }
    }

    func testEveryPrayerMomentHasUniqueBundledArtwork() throws {
        let assetNames = PrayerMomentArt.allCases.map(\.rawValue)

        XCTAssertEqual(
            Set(assetNames),
            Set(["PrayerFajr", "PrayerDhuhr", "PrayerAsr", "PrayerMaghrib", "PrayerIsha"])
        )
        XCTAssertEqual(assetNames.count, Set(assetNames).count, "Prayer artwork names must be unique")

        for assetName in assetNames {
            let image = try XCTUnwrap(UIImage(named: assetName), "Missing bundled artwork: \(assetName)")
            let pixels = try XCTUnwrap(image.cgImage, "Artwork is not a raster image: \(assetName)")
            XCTAssertEqual(pixels.width, 256, "\(assetName) must be 256 px wide")
            XCTAssertEqual(pixels.height, 256, "\(assetName) must be 256 px high")
            try assertArtworkHasTransparentBackground(image, assetName: assetName)
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

    private func assertArtworkHasTransparentBackground(
        _ image: UIImage,
        assetName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let source = try XCTUnwrap(
            image.cgImage,
            "Artwork is not a raster image: \(assetName)",
            file: file,
            line: line
        )
        let width = source.width
        let height = source.height
        let bytesPerRow = width * 4
        var rgba = [UInt8](repeating: 0, count: height * bytesPerRow)
        let context = try XCTUnwrap(
            CGContext(
                data: &rgba,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                    | CGImageAlphaInfo.premultipliedLast.rawValue
            ),
            "Could not decode alpha for \(assetName)",
            file: file,
            line: line
        )

        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))

        let alphaValues = stride(from: 3, to: rgba.count, by: 4).map { rgba[$0] }
        XCTAssertTrue(alphaValues.contains(0), "\(assetName) needs transparent pixels", file: file, line: line)
        XCTAssertTrue(alphaValues.contains(255), "\(assetName) needs opaque subject pixels", file: file, line: line)

        let cornerAlphaOffsets = [
            3,
            (width - 1) * 4 + 3,
            (height - 1) * bytesPerRow + 3,
            (height - 1) * bytesPerRow + (width - 1) * 4 + 3
        ]
        XCTAssertTrue(
            cornerAlphaOffsets.allSatisfy { rgba[$0] == 0 },
            "\(assetName) must be clear at every canvas corner",
            file: file,
            line: line
        )
    }
}
