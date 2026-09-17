import Foundation
import Supabase

struct CloudLibrarySnapshot: Codable, Equatable, Sendable {
    let revision: Int64
    let payload: [String: String]
}

protocol CloudLibraryRemote: Sendable {
    func fetch() async throws -> CloudLibrarySnapshot
    /// A nil response means the expected revision lost a race. Fetch the new
    /// snapshot and reapply the same pending changes before trying again.
    func compareAndSwap(payload: [String: String], expectedRevision: Int64) async throws -> CloudLibrarySnapshot?
}

/// The surrounding dictionary retains deletions even though value is nil.
/// Persist these changes until the server acknowledges the replacement.
struct CloudLibraryChange: Codable, Equatable, Sendable {
    let value: String?
}

enum CloudLibraryMerge {
    static func changes(from previous: [String: String], to current: [String: String]) -> [String: CloudLibraryChange] {
        var result: [String: CloudLibraryChange] = [:]
        for key in Set(previous.keys).union(current.keys) where previous[key] != current[key] {
            result[key] = CloudLibraryChange(value: current[key])
        }
        return result
    }

    /// Pending local edits win only the keys they touched. The server's other
    /// keys, including additions from another device, remain unchanged.
    static func applying(changes: [String: CloudLibraryChange], to remote: [String: String]) -> [String: String] {
        var result = remote
        for (key, change) in changes {
            if let value = change.value { result[key] = value }
            else { result.removeValue(forKey: key) }
        }
        return result
    }
}

enum CloudLibraryRemoteError: Error, Equatable {
    case accountChanged
    case documentTooLarge
    case tooManyRecords
    case invalidRevision
    case invalidResponse
}

enum CloudLibraryLimits {
    static let maximumBytes = 5 * 1_024 * 1_024
    static let maximumRecords = 30_000

    static func validate(_ payload: [String: String]) throws {
        guard payload.count <= maximumRecords else { throw CloudLibraryRemoteError.tooManyRecords }
        // Reject huge strings before allocating another complete JSON copy.
        var rawBytes = 0
        for (key, value) in payload {
            rawBytes += key.utf8.count + value.utf8.count
            guard rawBytes <= maximumBytes else { throw CloudLibraryRemoteError.documentTooLarge }
        }
        let encoder = JSONEncoder()
        // Postgres jsonb::text adds a space after each colon and separator.
        // Include that overhead so a locally accepted document also fits the
        // server constraint; the server remains the final size authority.
        let encoded = try encoder.encode(payload)
        guard encoded.count + payload.count * 2 <= maximumBytes else {
            throw CloudLibraryRemoteError.documentTooLarge
        }
    }
}

/// Bound to one account for its entire lifetime. RLS is the authority; the
/// pre/post identity checks also keep a stale result out of the local library.
struct SupabaseCloudLibraryRemote: CloudLibraryRemote {
    private let client: SupabaseClient
    private let userID: UUID

    init(client: SupabaseClient, userID: UUID) {
        self.client = client
        self.userID = userID
    }

    func fetch() async throws -> CloudLibrarySnapshot {
        try requireSameUser()
        try Task.checkCancellation()
        let rows: [CloudLibrarySnapshot] = try await client
            .from("account_library_documents")
            .select("revision,payload")
            .eq("user_id", value: userID.uuidString.lowercased())
            .limit(1)
            .execute()
            .value
        try Task.checkCancellation()
        try requireSameUser()
        guard let snapshot = rows.first else { return .init(revision: 0, payload: [:]) }
        guard rows.count == 1, snapshot.revision > 0 else { throw CloudLibraryRemoteError.invalidResponse }
        try CloudLibraryLimits.validate(snapshot.payload)
        return snapshot
    }

    func compareAndSwap(payload: [String: String], expectedRevision: Int64) async throws -> CloudLibrarySnapshot? {
        try requireSameUser()
        guard expectedRevision >= 0, expectedRevision < Int64.max else {
            throw CloudLibraryRemoteError.invalidRevision
        }
        try CloudLibraryLimits.validate(payload)
        try Task.checkCancellation()
        // The SDK may await a token refresh after our identity check. The RPC
        // verifies this assertion against auth.uid(), preventing an account
        // switch from uploading these records under another user's token.
        let snapshot: CloudLibrarySnapshot? = try await client
            .rpc("compare_and_swap_account_library", params: Parameters(
                userID: userID, expectedRevision: expectedRevision, payload: payload))
            .execute()
            .value
        try Task.checkCancellation()
        try requireSameUser()
        if let snapshot {
            guard snapshot.revision == expectedRevision + 1, snapshot.payload == payload else {
                throw CloudLibraryRemoteError.invalidResponse
            }
        }
        return snapshot
    }

    private func requireSameUser() throws {
        guard let session = client.auth.currentSession,
              session.user.id == userID, !session.user.isAnonymous else {
            throw CloudLibraryRemoteError.accountChanged
        }
    }

    private struct Parameters: Encodable {
        let userID: UUID
        let expectedRevision: Int64
        let payload: [String: String]
        enum CodingKeys: String, CodingKey {
            case userID = "p_user_id"
            case expectedRevision = "p_expected_revision"
            case payload = "p_payload"
        }
    }
}
