import Foundation
import XCTest
@testable import Sakina

@MainActor
final class ScholarContentTests: XCTestCase {
    func testConfigurationRejectsPlaceholdersAndAcceptsExplicitEnvironment() {
        XCTAssertNil(
            ScholarContentConfiguration.validated(
                supabaseURLString: "$(YAQEEN_SCHOLAR_SUPABASE_URL)",
                publishableKey: "replace-me"
            )
        )

        let configuration = ScholarContentConfiguration.validated(
            supabaseURLString: "https://example.supabase.co",
            publishableKey: "sb_publishable_test"
        )

        XCTAssertEqual(configuration?.supabaseURL.absoluteString, "https://example.supabase.co")
        XCTAssertEqual(configuration?.publishableKey, "sb_publishable_test")
    }

    func testCompositeKeyKeepsTheSameAyahSeparateAcrossSituations() async {
        let profile = verifiedProfile()
        let marriage = insight(id: "marriage", situationID: "marriageProblems", verseKey: "4:35")
        let conflict = insight(id: "conflict", situationID: "familyConflict", verseKey: "4:35")
        let client = ScholarContentClient(
            fetchVerifiedProfile: { profile },
            fetchPublishedInsights: { situationID in
                [marriage, conflict].filter { situationID == nil || $0.key.situationID == situationID }
            }
        )
        let store = ScholarContentStore(
            client: client,
            cache: ScholarContentCache(fileURL: nil)
        )

        await store.loadProfileAndPublishedInsights()

        XCTAssertEqual(
            store.insight(situationID: "marriageProblems", verseKey: "4:35")?.id,
            "marriage"
        )
        XCTAssertEqual(
            store.insight(situationID: "familyConflict", verseKey: "4:35")?.id,
            "conflict"
        )
    }

    func testResponseDecodingOnlyUsesReviewedEnglishAsDisplayCopy() throws {
        let reviewed = try decodeResponse(translationStatus: "reviewed")
        XCTAssertTrue(try XCTUnwrap(reviewed.insight).hasReviewedEnglishTranslation)
        XCTAssertEqual(reviewed.insight?.body(.english), "English review")
        XCTAssertEqual(reviewed.insight?.references.first?.title, "Reference label")
        XCTAssertEqual(reviewed.insight?.situationTitle(.english), "Marriage difficulties")

        let generated = try decodeResponse(translationStatus: "generated")
        XCTAssertFalse(try XCTUnwrap(generated.insight).hasReviewedEnglishTranslation)
        XCTAssertEqual(generated.insight?.body(.english), "—")
    }

    func testReferenceMaterialDecodesLossilyAndKeepsOnlyHTTPSLinks() throws {
        let response = try decodeResponse(
            translationStatus: "reviewed",
            referenceMaterialJSON: """
            [
              {
                "label": "Secure source",
                "url": "https://example.com/source"
              },
              "not an object",
              {
                "title": "   ",
                "url": "https://example.com/blank"
              },
              {
                "title": "Legacy HTTP source",
                "url": "http://example.com/legacy"
              },
              {
                "title": 17,
                "label": "Fallback label",
                "url": { "corrupt": true }
              },
              null
            ]
            """
        )

        let references = try XCTUnwrap(response.insight).references
        XCTAssertEqual(
            references.map(\.title),
            ["Secure source", "Legacy HTTP source", "Fallback label"]
        )
        XCTAssertEqual(references[0].url?.absoluteString, "https://example.com/source")
        XCTAssertNil(references[1].url)
        XCTAssertNil(references[2].url)
    }

    func testCacheReplacesOneSituationsPublishedSetWithoutTouchingAnother() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("published-content.json")
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let cache = ScholarContentCache(fileURL: fileURL)
        let profile = verifiedProfile()
        let first = insight(id: "first", situationID: "firstSituation", verseKey: "2:1")
        let second = insight(id: "second", situationID: "secondSituation", verseKey: "2:1")
        await cache.replaceAllWithVerifiedPublicProfile(profile, insights: [first, second])

        await cache.replaceInsights(forSituationID: "firstSituation", with: [])
        var payload = await cache.payload()
        XCTAssertEqual(payload.insights.map(\.id), ["second"])

        let replacement = insight(id: "replacement", situationID: "firstSituation", verseKey: "2:2")
        await cache.replaceInsights(forSituationID: "firstSituation", with: [replacement])
        payload = await cache.payload()

        XCTAssertEqual(Set(payload.insights.map(\.id)), Set(["second", "replacement"]))
        XCTAssertEqual(payload.profile, profile)
        XCTAssertTrue(payload.profileVerifiedByPublicEndpoint)
    }

    func testUnconfiguredWithoutVerifiedCacheUsesClearlyUnverifiedPlaceholder() async {
        let store = ScholarContentStore(
            client: nil,
            cache: ScholarContentCache(fileURL: nil)
        )

        await store.loadProfileAndPublishedInsights()

        XCTAssertEqual(store.profile, .bundledPlaceholder)
        XCTAssertEqual(store.profileSource, .localPlaceholder)
        XCTAssertFalse(store.profile.verified)
        XCTAssertFalse(store.hasVerifiedPublicProfile)
        XCTAssertTrue(store.allPublishedInsights.isEmpty)
        XCTAssertEqual(store.profileState, .unconfigured)
    }

    func testOfflineWithoutVerifiedCacheDoesNotPromoteLocalPlaceholder() async {
        let client = ScholarContentClient(
            fetchVerifiedProfile: { throw URLError(.notConnectedToInternet) },
            fetchPublishedInsights: { _ in [] }
        )
        let store = ScholarContentStore(
            client: client,
            cache: ScholarContentCache(fileURL: nil)
        )

        await store.loadProfileAndPublishedInsights()

        XCTAssertEqual(store.profileSource, .localPlaceholder)
        XCTAssertFalse(store.profile.verified)
        XCTAssertFalse(store.hasVerifiedPublicProfile)
        XCTAssertEqual(store.profileState, .offline)
    }

    func testUnconfiguredUsesOnlyPreviouslyEndpointVerifiedCache() async throws {
        let fileURL = temporaryCacheFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let cache = ScholarContentCache(fileURL: fileURL)
        let profile = verifiedProfile()
        let cachedInsight = insight(id: "cached", situationID: "cachedSituation", verseKey: "2:2")
        await cache.replaceAllWithVerifiedPublicProfile(profile, insights: [cachedInsight])

        let store = ScholarContentStore(client: nil, cache: cache)
        await store.loadProfileAndPublishedInsights()

        XCTAssertEqual(store.profile, profile)
        XCTAssertEqual(store.profileSource, .cachedVerified)
        XCTAssertTrue(store.hasVerifiedPublicProfile)
        XCTAssertEqual(
            store.insight(situationID: "cachedSituation", verseKey: "2:2")?.id,
            "cached"
        )
        XCTAssertEqual(store.profileState, .unconfigured)
    }

    func testSuccessfulNoPublicProfileResponseClearsPreviouslyVerifiedCache() async throws {
        let fileURL = temporaryCacheFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let cache = ScholarContentCache(fileURL: fileURL)
        let cachedProfile = verifiedProfile()
        let cachedInsight = insight(id: "stale", situationID: "staleSituation", verseKey: "9:1")
        await cache.replaceAllWithVerifiedPublicProfile(cachedProfile, insights: [cachedInsight])

        let client = ScholarContentClient(
            fetchVerifiedProfile: { nil },
            fetchPublishedInsights: { _ in
                XCTFail("Insights must not be fetched after an authoritative empty public-profile response.")
                return [cachedInsight]
            }
        )
        let store = ScholarContentStore(client: client, cache: cache)

        await store.loadProfileAndPublishedInsights()

        XCTAssertEqual(store.profile, .bundledPlaceholder)
        XCTAssertEqual(store.profileSource, .localPlaceholder)
        XCTAssertFalse(store.hasVerifiedPublicProfile)
        XCTAssertTrue(store.allPublishedInsights.isEmpty)
        XCTAssertNil(store.insight(situationID: "staleSituation", verseKey: "9:1"))
        XCTAssertEqual(store.profileState, .loaded)

        let payload = await cache.payload()
        XCTAssertNil(payload.profile)
        XCTAssertTrue(payload.insights.isEmpty)
        XCTAssertFalse(payload.profileVerifiedByPublicEndpoint)

        let nextLaunch = ScholarContentStore(client: nil, cache: cache)
        await nextLaunch.loadProfileAndPublishedInsights()
        XCTAssertEqual(nextLaunch.profileSource, .localPlaceholder)
        XCTAssertFalse(nextLaunch.hasVerifiedPublicProfile)
    }

    func testLegacyVerifiedFlagWithoutEndpointMarkerIsRejectedAndRemoved() async throws {
        let fileURL = temporaryCacheFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let legacyPayload = ScholarContentCachePayload(
            profile: verifiedProfile(),
            insights: [insight(id: "legacy", situationID: "legacy", verseKey: "1:1")]
        )
        let data = try ScholarCoding.encoder.encode(legacyPayload)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL)

        let cache = ScholarContentCache(fileURL: fileURL)
        let store = ScholarContentStore(client: nil, cache: cache)
        await store.loadProfileAndPublishedInsights()

        XCTAssertEqual(store.profileSource, .localPlaceholder)
        XCTAssertFalse(store.hasVerifiedPublicProfile)
        XCTAssertTrue(store.allPublishedInsights.isEmpty)

        let cleared = await cache.payload()
        XCTAssertNil(cleared.profile)
        XCTAssertTrue(cleared.insights.isEmpty)
    }

    private func decodeResponse(
        translationStatus: String,
        referenceMaterialJSON: String = """
        [
          {
            "id": "source-1",
            "label": "Reference label",
            "url": "https://example.com/source"
          }
        ]
        """
    ) throws -> ScholarInsightResponse {
        let json = """
        {
          "id": "decoded",
          "scholar_id": "scholar",
          "body_ar": "—",
          "body_en": "English review",
          "reference_material": \(referenceMaterialJSON),
          "translation_status": "\(translationStatus)",
          "published_at": "2026-08-11T00:00:00.000Z",
          "updated_at": "2026-08-11T00:00:00Z",
          "situation_id": "marriageProblems",
          "situation_title_en": "Marriage difficulties",
          "situation_title_ar": "مشكلات زوجية",
          "verse_key": "2:1"
        }
        """
        return try ScholarCoding.decoder.decode(
            ScholarInsightResponse.self,
            from: Data(json.utf8)
        )
    }

    private func verifiedProfile() -> ScholarProfile {
        ScholarProfile(
            id: "public-scholar",
            displayNameArabic: "Public Scholar",
            displayNameEnglish: "Public Scholar",
            titleArabic: nil,
            titleEnglish: nil,
            bioArabic: nil,
            bioEnglish: nil,
            avatarURL: nil,
            avatarAssetName: nil,
            instagramURL: nil,
            facebookURL: nil,
            verified: true
        )
    }

    private func temporaryCacheFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("published-content.json")
    }

    private func insight(id: String, situationID: String, verseKey: String) -> ScholarInsight {
        ScholarInsight(
            id: id,
            key: ScholarContentKey(situationID: situationID, verseKey: verseKey),
            scholarID: verifiedProfile().id,
            situationTitleEnglish: nil,
            situationTitleArabic: nil,
            bodyArabic: "—",
            bodyEnglish: nil,
            isEnglishTranslationReviewed: false,
            references: [],
            publishedAt: nil,
            updatedAt: Date(timeIntervalSince1970: 1)
        )
    }
}
