import Foundation

enum ScholarContentLoadState: Equatable {
    case idle
    case loading
    case loaded
    case offline
    case unconfigured
    case failed
}

enum ScholarProfileSource: Equatable, Sendable {
    /// Identity, portrait, and links supplied locally with the app. No online
    /// verification has succeeded, so the UI must label these as a placeholder.
    case localPlaceholder
    /// A profile previously returned by the verified public endpoint and saved
    /// for useful offline access.
    case cachedVerified
    /// A profile returned by the verified public endpoint in this session.
    case liveVerified
}

@MainActor
final class ScholarContentStore: ObservableObject {
    @Published private(set) var profile = ScholarProfile.bundledPlaceholder
    @Published private(set) var profileSource: ScholarProfileSource = .localPlaceholder
    @Published private(set) var profileState: ScholarContentLoadState = .idle
    @Published private(set) var allInsightsState: ScholarContentLoadState = .idle
    @Published private(set) var allPublishedInsights: [ScholarInsight] = []
    @Published private(set) var situationStates: [String: ScholarContentLoadState] = [:]
    @Published private(set) var insightsByKey: [ScholarContentKey: ScholarInsight] = [:]

    private let client: ScholarContentClient?
    private let cache: ScholarContentCache

    init(
        client: ScholarContentClient? = ScholarContentConfiguration.current().map {
            ScholarContentClient.live(configuration: $0)
        },
        cache: ScholarContentCache = ScholarContentCache()
    ) {
        self.client = client
        self.cache = cache
    }

    var hasVerifiedPublicProfile: Bool {
        profile.verified && profileSource != .localPlaceholder
    }

    var isShowingLocalPlaceholder: Bool {
        profileSource == .localPlaceholder
    }

    func insight(situationID: String, verseKey: String) -> ScholarInsight? {
        guard hasVerifiedPublicProfile,
              let insight = insightsByKey[
                ScholarContentKey(situationID: situationID, verseKey: verseKey)
              ],
              insight.scholarID == profile.id else {
            return nil
        }
        return insight
    }

    func state(for situationID: String) -> ScholarContentLoadState {
        situationStates[situationID] ?? .idle
    }

    func loadInsights(forSituationID situationID: String, force: Bool = false) async {
        if !force, state(for: situationID) == .loaded { return }

        let cached = await cache.insights(forSituationID: situationID)
        merge(cached)

        guard let client else {
            situationStates[situationID] = .unconfigured
            return
        }

        situationStates[situationID] = .loading
        do {
            let fetchedInsights = try await client.fetchPublishedInsights(situationID)
            guard !Task.isCancelled else { return }
            let insights = hasVerifiedPublicProfile
                ? fetchedInsights.filter { $0.scholarID == profile.id }
                : fetchedInsights
            replaceInsights(forSituationID: situationID, with: insights)
            await cache.replaceInsights(forSituationID: situationID, with: insights)
            situationStates[situationID] = .loaded
        } catch is CancellationError {
            return
        } catch {
            situationStates[situationID] = isOffline(error) ? .offline : .failed
        }
    }

    func loadProfileAndPublishedInsights(force: Bool = false) async {
        if !force, profileState == .loaded, allInsightsState == .loaded { return }

        let cached = await cache.payload()
        if let cachedProfile = cached.verifiedPublicProfile {
            profile = cachedProfile
            profileSource = .cachedVerified
            let cachedInsights = cached.verifiedInsights.filter { $0.scholarID == cachedProfile.id }
            allPublishedInsights = sorted(cachedInsights)
            replaceAllInsights(with: cachedInsights)
        } else {
            showLocalPlaceholder()
            if cached.profile != nil || !cached.insights.isEmpty {
                // Old app versions could cache the bundled placeholder as
                // verified. The endpoint-verification marker deliberately
                // rejects and removes that legacy data.
                await cache.clearPublicContent()
            }
        }

        guard let client else {
            profileState = .unconfigured
            allInsightsState = .unconfigured
            return
        }

        profileState = .loading
        allInsightsState = .loading
        do {
            let remoteProfile = try await client.fetchVerifiedProfile()
            guard !Task.isCancelled else { return }

            guard let remoteProfile, remoteProfile.verified else {
                // A successful empty response is authoritative: the profile is
                // no longer explicitly public/verified. Clear stale identity
                // and insight cache instead of treating this like an outage.
                showLocalPlaceholder()
                await cache.clearPublicContent()
                profileState = .loaded
                allInsightsState = .loaded
                return
            }

            profile = remoteProfile
            profileSource = .liveVerified
            let compatibleSavedInsights = allPublishedInsights.filter {
                $0.scholarID == remoteProfile.id
            }
            allPublishedInsights = sorted(compatibleSavedInsights)
            replaceAllInsights(with: compatibleSavedInsights)
            await cache.replaceVerifiedProfilePreservingInsights(remoteProfile)

            let fetchedInsights = try await client.fetchPublishedInsights(nil)
            guard !Task.isCancelled else { return }
            let remoteInsights = fetchedInsights.filter { $0.scholarID == remoteProfile.id }
            allPublishedInsights = sorted(remoteInsights)
            replaceAllInsights(with: remoteInsights)
            await cache.replaceAllWithVerifiedPublicProfile(
                remoteProfile,
                insights: remoteInsights
            )
            profileState = .loaded
            allInsightsState = .loaded
        } catch is CancellationError {
            return
        } catch {
            let state: ScholarContentLoadState = isOffline(error) ? .offline : .failed
            profileState = state
            allInsightsState = state
        }
    }

    private func showLocalPlaceholder() {
        profile = .bundledPlaceholder
        profileSource = .localPlaceholder
        allPublishedInsights = []
        replaceAllInsights(with: [])
    }

    private func merge(_ insights: [ScholarInsight]) {
        for insight in insights {
            if let current = insightsByKey[insight.key], current.updatedAt > insight.updatedAt {
                continue
            }
            insightsByKey[insight.key] = insight
        }
    }

    private func replaceInsights(forSituationID situationID: String, with insights: [ScholarInsight]) {
        insightsByKey = insightsByKey.filter { $0.key.situationID != situationID }
        merge(insights)
    }

    private func replaceAllInsights(with insights: [ScholarInsight]) {
        insightsByKey = [:]
        merge(insights)
    }

    private func sorted(_ insights: [ScholarInsight]) -> [ScholarInsight] {
        insights.sorted {
            ($0.publishedAt ?? $0.updatedAt) > ($1.publishedAt ?? $1.updatedAt)
        }
    }

    private func isOffline(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        return [
            .notConnectedToInternet,
            .networkConnectionLost,
            .timedOut,
            .cannotFindHost,
            .cannotConnectToHost,
            .dnsLookupFailed,
            .internationalRoamingOff,
            .dataNotAllowed
        ].contains(urlError.code)
    }
}

struct ScholarContentCachePayload: Codable, Sendable {
    var profile: ScholarProfile?
    var insights: [ScholarInsight]
    /// Missing on legacy payloads by design. Only a successful response from
    /// `public_scholar_profiles` is allowed to set this marker.
    var profileVerifiedByPublicEndpoint: Bool

    init(
        profile: ScholarProfile?,
        insights: [ScholarInsight],
        profileVerifiedByPublicEndpoint: Bool = false
    ) {
        self.profile = profile
        self.insights = insights
        self.profileVerifiedByPublicEndpoint = profileVerifiedByPublicEndpoint
    }

    var verifiedPublicProfile: ScholarProfile? {
        guard profileVerifiedByPublicEndpoint,
              let profile,
              profile.verified else { return nil }
        return profile
    }

    var verifiedInsights: [ScholarInsight] {
        verifiedPublicProfile == nil ? [] : insights
    }

    static let empty = ScholarContentCachePayload(
        profile: nil,
        insights: [],
        profileVerifiedByPublicEndpoint: false
    )

    enum CodingKeys: String, CodingKey {
        case profile
        case insights
        case profileVerifiedByPublicEndpoint = "profile_verified_by_public_endpoint"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decodeIfPresent(ScholarProfile.self, forKey: .profile)
        insights = try container.decodeIfPresent([ScholarInsight].self, forKey: .insights) ?? []
        profileVerifiedByPublicEndpoint = try container.decodeIfPresent(
            Bool.self,
            forKey: .profileVerifiedByPublicEndpoint
        ) ?? false
    }
}

actor ScholarContentCache {
    private let fileURL: URL?

    init(fileURL: URL? = ScholarContentCache.defaultFileURL) {
        self.fileURL = fileURL
    }

    func payload() -> ScholarContentCachePayload {
        guard let fileURL,
              let data = try? Data(contentsOf: fileURL),
              let payload = try? ScholarCoding.decoder.decode(
                  ScholarContentCachePayload.self,
                  from: data
              ) else {
            return .empty
        }
        return payload
    }

    func insights(forSituationID situationID: String) -> [ScholarInsight] {
        payload().verifiedInsights.filter { $0.key.situationID == situationID }
    }

    func replaceInsights(forSituationID situationID: String, with insights: [ScholarInsight]) {
        var cached = payload()
        guard cached.verifiedPublicProfile != nil else { return }
        cached.insights.removeAll { $0.key.situationID == situationID }
        cached.insights.append(contentsOf: insights)
        write(cached)
    }

    func replaceVerifiedProfilePreservingInsights(_ profile: ScholarProfile) {
        guard profile.verified else {
            clearPublicContent()
            return
        }
        let existingInsights = payload().verifiedInsights.filter { $0.scholarID == profile.id }
        write(
            ScholarContentCachePayload(
                profile: profile,
                insights: existingInsights,
                profileVerifiedByPublicEndpoint: true
            )
        )
    }

    func replaceAllWithVerifiedPublicProfile(
        _ profile: ScholarProfile,
        insights: [ScholarInsight]
    ) {
        guard profile.verified else {
            clearPublicContent()
            return
        }
        write(
            ScholarContentCachePayload(
                profile: profile,
                insights: insights.filter { $0.scholarID == profile.id },
                profileVerifiedByPublicEndpoint: true
            )
        )
    }

    func clearPublicContent() {
        write(.empty)
    }

    private func write(_ payload: ScholarContentCachePayload) {
        guard let fileURL,
              let data = try? ScholarCoding.encoder.encode(payload) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: .atomic)
    }

    fileprivate static var defaultFileURL: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("ScholarPublicContent", isDirectory: true)
            .appendingPathComponent("published-content.json", isDirectory: false)
    }
}
