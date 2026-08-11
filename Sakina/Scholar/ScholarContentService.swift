import Foundation
import Supabase

struct ScholarContentConfiguration: Equatable, Sendable {
    let supabaseURL: URL
    let publishableKey: String

    /// Values can be supplied by Info.plist entries expanded from build settings,
    /// or by process environment variables during local development. No endpoint
    /// or key is bundled in source control.
    static func current(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> ScholarContentConfiguration? {
        let urlString = configuredValue(
            infoValue: bundle.object(forInfoDictionaryKey: "YaqeenScholarSupabaseURL") as? String,
            environmentValue: environment["YAQEEN_SCHOLAR_SUPABASE_URL"]
        )
        let key = configuredValue(
            infoValue: bundle.object(forInfoDictionaryKey: "YaqeenScholarSupabasePublishableKey") as? String,
            environmentValue: environment["YAQEEN_SCHOLAR_SUPABASE_PUBLISHABLE_KEY"]
        )

        return validated(supabaseURLString: urlString, publishableKey: key)
    }

    static func validated(
        supabaseURLString: String?,
        publishableKey: String?
    ) -> ScholarContentConfiguration? {
        guard let urlString = configuredValue(infoValue: supabaseURLString, environmentValue: nil),
              let key = configuredValue(infoValue: publishableKey, environmentValue: nil),
              let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              scheme == "https",
              url.host != nil else {
            return nil
        }

        return ScholarContentConfiguration(supabaseURL: url, publishableKey: key)
    }

    private static func configuredValue(
        infoValue: String?,
        environmentValue: String?
    ) -> String? {
        [infoValue, environmentValue]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { value in
                !value.isEmpty
                    && !value.contains("$(")
                    && !value.localizedCaseInsensitiveContains("replace-me")
            }
    }
}

struct ScholarContentClient: Sendable {
    var fetchVerifiedProfile: @Sendable () async throws -> ScholarProfile?
    var fetchPublishedInsights: @Sendable (_ situationID: String?) async throws -> [ScholarInsight]

    static func live(
        configuration: ScholarContentConfiguration
    ) -> ScholarContentClient {
        let service = SupabaseScholarContentService(
            configuration: configuration
        )

        return ScholarContentClient(
            fetchVerifiedProfile: { try await service.fetchVerifiedProfile() },
            fetchPublishedInsights: { situationID in
                try await service.fetchPublishedInsights(situationID: situationID)
            }
        )
    }

    static let unavailable = ScholarContentClient(
        fetchVerifiedProfile: { nil },
        fetchPublishedInsights: { _ in [] }
    )
}

private struct SupabaseScholarContentService: Sendable {
    let configuration: ScholarContentConfiguration
    let client: SupabaseClient

    init(configuration: ScholarContentConfiguration) {
        self.configuration = configuration
        client = SupabaseClient(
            supabaseURL: configuration.supabaseURL,
            supabaseKey: configuration.publishableKey
        )
    }

    func fetchVerifiedProfile() async throws -> ScholarProfile? {
        let rows: [PublicScholarProfileResponse] = try await client
            .from("public_scholar_profiles")
            .select(
                "scholar_id,display_name_ar,display_name_en,title_ar,title_en,bio_ar,bio_en,avatar_path,instagram_url,facebook_url,verified"
            )
            .limit(1)
            .execute()
            .value
        return rows.first?.profile(baseURL: configuration.supabaseURL)
    }

    func fetchPublishedInsights(situationID: String?) async throws -> [ScholarInsight] {
        var query = client
            .from("published_scholar_content")
            .select(
                "id,situation_id,situation_title_en,situation_title_ar,verse_key,scholar_id,body_ar,body_en,reference_material,translation_status,published_at,updated_at"
            )

        if let situationID {
            query = query.eq("situation_id", value: situationID)
        }

        let rows: [ScholarInsightResponse] = try await query
            .order("published_at", ascending: false)
            .execute()
            .value
        return rows.compactMap(\.insight)
    }
}

private struct PublicScholarProfileResponse: Decodable {
    let scholarID: String
    let displayNameArabic: String?
    let displayNameEnglish: String
    let titleArabic: String?
    let titleEnglish: String?
    let bioArabic: String?
    let bioEnglish: String?
    let avatarPath: String?
    let instagramURL: URL?
    let facebookURL: URL?
    let verified: Bool

    enum CodingKeys: String, CodingKey {
        case scholarID = "scholar_id"
        case displayNameArabic = "display_name_ar"
        case displayNameEnglish = "display_name_en"
        case titleArabic = "title_ar"
        case titleEnglish = "title_en"
        case bioArabic = "bio_ar"
        case bioEnglish = "bio_en"
        case avatarPath = "avatar_path"
        case instagramURL = "instagram_url"
        case facebookURL = "facebook_url"
        case verified
    }

    func profile(baseURL: URL) -> ScholarProfile? {
        guard verified,
              let englishName = nonempty(displayNameEnglish) else { return nil }
        return ScholarProfile(
            id: scholarID,
            displayNameArabic: nonempty(displayNameArabic) ?? englishName,
            displayNameEnglish: englishName,
            titleArabic: nonempty(titleArabic),
            titleEnglish: nonempty(titleEnglish),
            bioArabic: nonempty(bioArabic),
            bioEnglish: nonempty(bioEnglish),
            avatarURL: avatarURL(baseURL: baseURL),
            avatarAssetName: nil,
            instagramURL: instagramURL,
            facebookURL: facebookURL,
            verified: true
        )
    }

    private func avatarURL(baseURL: URL) -> URL? {
        guard let path = nonempty(avatarPath) else { return nil }
        let root = baseURL
            .appendingPathComponent("storage")
            .appendingPathComponent("v1")
            .appendingPathComponent("object")
            .appendingPathComponent("public")
            .appendingPathComponent("scholar-avatars")
        return path.split(separator: "/").reduce(root) { url, component in
            url.appendingPathComponent(String(component))
        }
    }
}

struct ScholarInsightResponse: Decodable {
    let id: String
    let situationID: String
    let situationTitleEnglish: String?
    let situationTitleArabic: String?
    let verseKey: String
    let scholarID: String
    let bodyArabic: String
    let bodyEnglish: String?
    private let referenceMaterial: LossyScholarInsightReferenceArray
    let translationStatus: String
    let publishedAt: Date?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case situationID = "situation_id"
        case situationTitleEnglish = "situation_title_en"
        case situationTitleArabic = "situation_title_ar"
        case verseKey = "verse_key"
        case scholarID = "scholar_id"
        case bodyArabic = "body_ar"
        case bodyEnglish = "body_en"
        case referenceMaterial = "reference_material"
        case translationStatus = "translation_status"
        case publishedAt = "published_at"
        case updatedAt = "updated_at"
    }

    var insight: ScholarInsight? {
        let arabic = bodyArabic.trimmingCharacters(in: .whitespacesAndNewlines)
        let english = bodyEnglish?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !arabic.isEmpty else { return nil }

        return ScholarInsight(
            id: id,
            key: ScholarContentKey(
                situationID: situationID,
                verseKey: verseKey
            ),
            scholarID: scholarID,
            situationTitleEnglish: nonempty(situationTitleEnglish),
            situationTitleArabic: nonempty(situationTitleArabic),
            bodyArabic: arabic,
            bodyEnglish: english,
            isEnglishTranslationReviewed: translationStatus == "reviewed",
            references: referenceMaterial.values,
            publishedAt: publishedAt,
            updatedAt: updatedAt
        )
    }
}

private struct LossyScholarInsightReferenceArray: Decodable {
    let values: [ScholarInsightReference]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var decoded: [ScholarInsightReference] = []

        while !container.isAtEnd {
            // `superDecoder()` advances exactly one array element even when
            // that element cannot be decoded as a reference.
            let elementDecoder = try container.superDecoder()
            if let reference = try? ScholarInsightReference(from: elementDecoder) {
                decoded.append(reference)
            }
        }

        values = decoded
    }
}

private func nonempty(_ value: String?) -> String? {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? nil : trimmed
}

enum ScholarCoding {
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = fractionalISO8601.date(from: value) ?? standardISO8601.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO-8601 date"
            )
        }
        return decoder
    }

    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static let fractionalISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let standardISO8601 = ISO8601DateFormatter()
}
