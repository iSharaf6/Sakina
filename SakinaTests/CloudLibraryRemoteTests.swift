import Foundation
import Supabase
import XCTest
@testable import Sakina

@MainActor
final class CloudLibraryRemoteTests: XCTestCase {
    func testRebasingIndependentDeviceEditsPreservesBothLibraries() {
        let base = ["note:one": "original", "saved:shared": "ayat"]
        let local = ["note:one": "edited on this phone", "saved:shared": "ayat"]
        let otherDevice = ["note:one": "original", "saved:shared": "ayat", "note:two": "from the other phone"]
        let pending = CloudLibraryMerge.changes(from: base, to: local)
        XCTAssertEqual(CloudLibraryMerge.applying(changes: pending, to: otherDevice),
                       ["note:one": "edited on this phone", "saved:shared": "ayat", "note:two": "from the other phone"])
    }

    func testDeletionSurvivesDurableRoundTripAndARevisionConflict() throws {
        let pending = CloudLibraryMerge.changes(from: ["note:removed": "private note"], to: [:])
        let restored = try JSONDecoder().decode([String: CloudLibraryChange].self,
                                                from: JSONEncoder().encode(pending))
        XCTAssertNotNil(restored["note:removed"], "A tombstone must not become an absent dictionary entry")
        XCTAssertNil(restored["note:removed"]?.value)
        let refreshed = ["note:removed": "updated remotely before deletion", "saved:other": "keep"]
        let result = CloudLibraryMerge.applying(changes: restored, to: refreshed)
        XCTAssertNil(result["note:removed"], "Rebasing after a conflict must not resurrect the deleted record")
        XCTAssertEqual(result["saved:other"], "keep")
    }

    func testUnchangedLocalRecordsDoNotUndoRemoteDeletionOrNewValues() {
        let unchanged = ["note:one": "old", "saved:removed-remotely": "old"]
        let pending = CloudLibraryMerge.changes(from: unchanged, to: unchanged)
        XCTAssertTrue(pending.isEmpty)
        XCTAssertEqual(CloudLibraryMerge.applying(changes: pending, to: ["note:one": "new"]), ["note:one": "new"])
    }

    func testPendingLocalValueWinsSameKeyAndEmptyStringIsNotDeletion() {
        let pending = CloudLibraryMerge.changes(from: ["note:one": "base", "note:two": "base"],
                                               to: ["note:one": "local", "note:two": ""])
        let result = CloudLibraryMerge.applying(changes: pending,
                                               to: ["note:one": "remote", "note:two": "remote"])
        XCTAssertEqual(result, ["note:one": "local", "note:two": ""])
        XCTAssertEqual(CloudLibraryMerge.changes(from: [:], to: [:]), [:])
    }

    func testLimitsCountEncodedBytesAndRecordsIncludingEscapedText() throws {
        XCTAssertNoThrow(try CloudLibraryLimits.validate(["note": "دعاء باللغة العربية"]))
        XCTAssertThrowsError(try CloudLibraryLimits.validate(["note": String(repeating: "a", count: CloudLibraryLimits.maximumBytes)])) {
            XCTAssertEqual($0 as? CloudLibraryRemoteError, .documentTooLarge)
        }
        // Escaping doubles these characters even though their raw UTF-8 fits.
        XCTAssertThrowsError(try CloudLibraryLimits.validate(["note": String(repeating: "\"", count: CloudLibraryLimits.maximumBytes / 2)])) {
            XCTAssertEqual($0 as? CloudLibraryRemoteError, .documentTooLarge)
        }
        let tooMany = Dictionary(uniqueKeysWithValues: (0...CloudLibraryLimits.maximumRecords).map { (String($0), "") })
        XCTAssertThrowsError(try CloudLibraryLimits.validate(tooMany)) {
            XCTAssertEqual($0 as? CloudLibraryRemoteError, .tooManyRecords)
        }
    }

    func testFetchFiltersByOwnerAndDistinguishesNoBackupFromStoredData() async throws {
        for (body, expected) in [
            ("[]", CloudLibrarySnapshot(revision: 0, payload: [:])),
            (#"[{"revision":4,"payload":{"note:one":"saved"}}]"#,
             CloudLibrarySnapshot(revision: 4, payload: ["note:one": "saved"]))
        ] {
            let client = makeClient { request in
                XCTAssertEqual(request.url?.path, "/rest/v1/account_library_documents")
                XCTAssertEqual(request.httpMethod, "GET")
                let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
                XCTAssertEqual(query.first(where: { $0.name == "user_id" })?.value,
                               "eq.\(cloudTestUserID.uuidString.lowercased())")
                return .init(json: body)
            }
            try await signIn(client)
            let snapshot = try await SupabaseCloudLibraryRemote(client: client, userID: cloudTestUserID).fetch()
            XCTAssertEqual(snapshot, expected)
        }
    }

    func testCASBindsOwnerAndReturnsNilOnAConflict() async throws {
        let payload = ["note:one": "my local edit"]
        let client = makeClient { request in
            XCTAssertEqual(request.url?.path, "/rest/v1/rpc/compare_and_swap_account_library")
            XCTAssertEqual(request.httpMethod, "POST")
            let body = try XCTUnwrap(JSONSerialization.jsonObject(with: cloudRequestBody(request)) as? [String: Any])
            XCTAssertEqual((body["p_user_id"] as? String)?.lowercased(), cloudTestUserID.uuidString.lowercased())
            XCTAssertEqual(body["p_expected_revision"] as? Int, 7)
            XCTAssertEqual(body["p_payload"] as? [String: String], payload)
            return .init(json: "null")
        }
        try await signIn(client)
        let remote = SupabaseCloudLibraryRemote(client: client, userID: cloudTestUserID)
        let result = try await remote.compareAndSwap(payload: payload, expectedRevision: 7)
        XCTAssertNil(result)
    }

    func testSuccessfulCASRequiresAnExactAcknowledgement() async throws {
        let client = makeClient { _ in .init(json: #"{"revision":3,"payload":{"note":"acknowledged"}}"#) }
        try await signIn(client)
        let remote = SupabaseCloudLibraryRemote(client: client, userID: cloudTestUserID)
        let result = try await remote.compareAndSwap(payload: ["note": "acknowledged"], expectedRevision: 2)
        XCTAssertEqual(result, .init(revision: 3, payload: ["note": "acknowledged"]))
        do {
            _ = try await remote.compareAndSwap(payload: ["note": "different"], expectedRevision: 2)
            XCTFail("A mismatched acknowledgement must leave pending edits unacknowledged")
        } catch { XCTAssertEqual(error as? CloudLibraryRemoteError, .invalidResponse) }
    }

    func testSignedOutOrDifferentAccountNeverSendsLibraryRequests() async throws {
        let client = makeClient { _ in
            XCTFail("The local identity guard must reject this before network I/O")
            return .init(status: 500, json: "{}")
        }
        let remote = SupabaseCloudLibraryRemote(client: client, userID: cloudTestUserID)
        do { _ = try await remote.fetch(); XCTFail("Signed-out fetch must fail") }
        catch { XCTAssertEqual(error as? CloudLibraryRemoteError, .accountChanged) }
        try await signIn(client)
        let otherAccount = SupabaseCloudLibraryRemote(client: client, userID: UUID())
        do {
            _ = try await otherAccount.compareAndSwap(payload: ["note": "never send"], expectedRevision: 0)
            XCTFail("A stale account client must not upload")
        } catch { XCTAssertEqual(error as? CloudLibraryRemoteError, .accountChanged) }
    }

    func testResponseFromSignedOutAccountIsNeverReturnedToLocalLibrary() async throws {
        let started = expectation(description: "Library request started")
        let gate = CloudLibraryResponseGate()
        defer { gate.release() }
        let client = makeClient { request in
            if request.url?.path == "/auth/v1/logout" { return .init(json: "{}") }
            started.fulfill()
            return .init(json: #"[{"revision":2,"payload":{"note":"previous account"}}]"#, gate: gate)
        }
        try await signIn(client)
        let remote = SupabaseCloudLibraryRemote(client: client, userID: cloudTestUserID)
        let pending = Task { try await remote.fetch() }
        await fulfillment(of: [started], timeout: 2)
        try await client.auth.signOut(scope: .local)
        XCTAssertNil(client.auth.currentUser)
        gate.release()
        do { _ = try await pending.value; XCTFail("A stale response must not reach the local restore path") }
        catch { XCTAssertEqual(error as? CloudLibraryRemoteError, .accountChanged) }
    }

    func testInvalidRevisionAndOversizedWriteNeverReachBackend() async throws {
        let client = makeClient { _ in
            XCTFail("Malformed writes must fail before network I/O")
            return .init(status: 500, json: "{}")
        }
        try await signIn(client)
        let remote = SupabaseCloudLibraryRemote(client: client, userID: cloudTestUserID)
        for revision in [Int64(-1), Int64.max] {
            do { _ = try await remote.compareAndSwap(payload: [:], expectedRevision: revision); XCTFail("Invalid revision") }
            catch { XCTAssertEqual(error as? CloudLibraryRemoteError, .invalidRevision) }
        }
        do {
            _ = try await remote.compareAndSwap(payload: ["note": String(repeating: "a", count: CloudLibraryLimits.maximumBytes)], expectedRevision: 0)
            XCTFail("Oversized write")
        } catch { XCTAssertEqual(error as? CloudLibraryRemoteError, .documentTooLarge) }
    }

    private func signIn(_ client: SupabaseClient) async throws {
        _ = try await client.auth.verifyOTP(email: "reader@example.test", token: "123456", type: .email)
        XCTAssertEqual(client.auth.currentUser?.id, cloudTestUserID)
    }

    private func makeClient(handler: @escaping CloudLibraryRequestStub.Handler) -> SupabaseClient {
        let host = "library-\(UUID().uuidString.lowercased()).example.test"
        CloudLibraryRequestStub.registry.set({ request in
            if request.url?.path == "/auth/v1/verify" { return .init(json: cloudTestSessionJSON) }
            return try handler(request)
        }, for: host)
        addTeardownBlock { CloudLibraryRequestStub.registry.remove(host) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CloudLibraryRequestStub.self]
        return SupabaseClient(supabaseURL: URL(string: "https://\(host)")!, supabaseKey: "test-publishable-key",
            options: .init(auth: .init(storage: CloudLibraryAuthStorage(), autoRefreshToken: false,
                                      emitLocalSessionAsInitialSession: true),
                           global: .init(session: URLSession(configuration: configuration))))
    }
}

let cloudTestUserID = UUID(uuidString: "FAD28276-D725-4927-9B57-AF9D79E9FF60")!
var cloudTestSessionJSON: String {
    let user = #"{"id":"FAD28276-D725-4927-9B57-AF9D79E9FF60","aud":"authenticated","email":"reader@example.test","app_metadata":{},"user_metadata":{},"created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z","identities":[],"is_anonymous":false}"#
    return "{\"access_token\":\"test-session-token\",\"token_type\":\"bearer\",\"expires_in\":3600,\"expires_at\":\(Date().timeIntervalSince1970 + 3600),\"refresh_token\":\"test-refresh-token\",\"user\":\(user)}"
}

private func cloudRequestBody(_ request: URLRequest) -> Data {
    if let data = request.httpBody { return data }
    guard let stream = request.httpBodyStream else { return Data() }
    stream.open()
    defer { stream.close() }
    var data = Data(), buffer = [UInt8](repeating: 0, count: 4096)
    while stream.hasBytesAvailable {
        let count = stream.read(&buffer, maxLength: buffer.count)
        guard count > 0 else { break }
        data.append(buffer, count: count)
    }
    return data
}

final class CloudLibraryAuthStorage: AuthLocalStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Data] = [:]
    func store(key: String, value: Data) { lock.lock(); defer { lock.unlock() }; values[key] = value }
    func retrieve(key: String) -> Data? { lock.lock(); defer { lock.unlock() }; return values[key] }
    func remove(key: String) { lock.lock(); defer { lock.unlock() }; values.removeValue(forKey: key) }
}

final class CloudLibraryRequestStub: URLProtocol, @unchecked Sendable {
    struct Response: Sendable {
        var status = 200
        let json: String
        var gate: CloudLibraryResponseGate? = nil
    }
    typealias Handler = @Sendable (URLRequest) throws -> Response
    final class Registry: @unchecked Sendable {
        private let lock = NSLock()
        private var handlers: [String: Handler] = [:]
        func set(_ handler: @escaping Handler, for host: String) { lock.lock(); defer { lock.unlock() }; handlers[host] = handler }
        func remove(_ host: String) { lock.lock(); defer { lock.unlock() }; handlers.removeValue(forKey: host) }
        func handler(for host: String) -> Handler? { lock.lock(); defer { lock.unlock() }; return handlers[host] }
    }
    static let registry = Registry()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            guard let url = request.url, let host = url.host, let handler = Self.registry.handler(for: host) else {
                throw URLError(.unsupportedURL)
            }
            let response = try handler(request)
            let deliver: @Sendable () -> Void = { [self] in
                client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: response.status, httpVersion: nil,
                                                                    headerFields: ["Content-Type": "application/json"])!,
                                    cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: Data(response.json.utf8))
                client?.urlProtocolDidFinishLoading(self)
            }
            if let gate = response.gate { gate.enqueue(deliver) }
            else { deliver() }
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

/// Deterministic delayed response, with no timing race or real network access.
final class CloudLibraryResponseGate: @unchecked Sendable {
    private let lock = NSLock()
    private var released = false
    private var delivery: (@Sendable () -> Void)?
    func enqueue(_ action: @escaping @Sendable () -> Void) {
        lock.lock()
        if released { lock.unlock(); action() }
        else { delivery = action; lock.unlock() }
    }
    func release() {
        lock.lock()
        released = true
        let action = delivery
        delivery = nil
        lock.unlock()
        action?()
    }
}
