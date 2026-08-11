import Foundation

/// Stable public-content identity. The same ayah can receive different guidance
/// in different situations, so neither field is sufficient on its own.
struct ScholarContentKey: Codable, Hashable, Identifiable, Sendable {
    let situationID: String
    let verseKey: String

    var id: String { "\(situationID)::\(verseKey)" }

    enum CodingKeys: String, CodingKey {
        case situationID = "situation_id"
        case verseKey = "verse_key"
    }
}

struct ScholarInsightReference: Codable, Hashable, Identifiable, Sendable {
    let title: String
    let detail: String?
    let url: URL?

    init(title: String, detail: String? = nil, url: URL? = nil) {
        self.title = title
        self.detail = detail
        self.url = url
    }

    enum CodingKeys: String, CodingKey {
        case title
        case label
        case detail
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedTitle = (try? container.decode(String.self, forKey: .title))
            ?? (try? container.decode(String.self, forKey: .label))
            ?? ""
        let trimmedTitle = decodedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .title,
                in: container,
                debugDescription: "A scholar reference requires a title or label."
            )
        }
        title = trimmedTitle
        detail = try? container.decode(String.self, forKey: .detail)

        let decodedURL = try? container.decode(URL.self, forKey: .url)
        if let decodedURL,
           decodedURL.scheme?.lowercased() == "https",
           decodedURL.host != nil {
            url = decodedURL
        } else {
            // References may omit a URL. Legacy/corrupt non-HTTPS values are
            // treated as absent rather than making the full insight unusable.
            url = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(detail, forKey: .detail)
        try container.encodeIfPresent(url, forKey: .url)
    }

    var id: String {
        [title, detail ?? "", url?.absoluteString ?? ""].joined(separator: "::")
    }
}

struct ScholarProfile: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let displayNameArabic: String
    let displayNameEnglish: String
    let titleArabic: String?
    let titleEnglish: String?
    let bioArabic: String?
    let bioEnglish: String?
    let avatarURL: URL?
    let avatarAssetName: String?
    let instagramURL: URL?
    let facebookURL: URL?
    let verified: Bool

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case displayNameArabic = "display_name_ar"
        case displayNameEnglish = "display_name_en"
        case titleArabic = "title_ar"
        case titleEnglish = "title_en"
        case bioArabic = "bio_ar"
        case bioEnglish = "bio_en"
        case avatarURL = "avatar_url"
        case avatarAssetName = "avatar_asset_name"
        case instagramURL = "instagram_url"
        case facebookURL = "facebook_url"
        case verified
    }

    func displayName(_ language: AppLanguage) -> String {
        language.pick(displayNameEnglish, displayNameArabic)
    }

    func secondaryDisplayName(_ language: AppLanguage) -> String {
        language.pick(displayNameArabic, displayNameEnglish)
    }

    func title(_ language: AppLanguage) -> String? {
        let value = language.pick(titleEnglish ?? "", titleArabic ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    func biography(_ language: AppLanguage) -> String? {
        let value = language.pick(bioEnglish ?? "", bioArabic ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    /// Local, explicitly unverified placeholder assembled only from material
    /// supplied by the app owner. It must never be promoted to public/verified
    /// content without a successful response from the public profile endpoint.
    static let bundledPlaceholder = ScholarProfile(
        id: "local-placeholder-abdullah-abu-hatab",
        displayNameArabic: "Dr. Abdullah Abu Hatab",
        displayNameEnglish: "Dr. Abdullah Abu Hatab",
        titleArabic: nil,
        titleEnglish: nil,
        bioArabic: nil,
        bioEnglish: nil,
        avatarURL: nil,
        avatarAssetName: "ScholarAbdullahAbuHatab",
        instagramURL: URL(string: "https://instagram.com/Dr.AbdullahAbuHatab"),
        facebookURL: URL(string: "https://facebook.com/Dr.AbdullahAbuHatab"),
        verified: false
    )
}

struct ScholarInsight: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let key: ScholarContentKey
    let scholarID: String
    let situationTitleEnglish: String?
    let situationTitleArabic: String?
    let bodyArabic: String
    let bodyEnglish: String?
    let isEnglishTranslationReviewed: Bool
    let references: [ScholarInsightReference]
    let publishedAt: Date?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case key
        case scholarID = "scholar_id"
        case situationTitleEnglish = "situation_title_en"
        case situationTitleArabic = "situation_title_ar"
        case bodyArabic = "body_ar"
        case bodyEnglish = "body_en"
        case isEnglishTranslationReviewed = "english_translation_reviewed"
        case references
        case publishedAt = "published_at"
        case updatedAt = "updated_at"
    }

    var hasReviewedEnglishTranslation: Bool {
        isEnglishTranslationReviewed
            && !(bodyEnglish ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func body(_ language: AppLanguage) -> String {
        if language == .english, hasReviewedEnglishTranslation {
            return bodyEnglish ?? bodyArabic
        }
        return bodyArabic
    }

    func situationTitle(_ language: AppLanguage) -> String? {
        let value = language.pick(situationTitleEnglish ?? "", situationTitleArabic ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
