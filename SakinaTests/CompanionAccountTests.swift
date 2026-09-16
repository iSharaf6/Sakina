import AuthenticationServices
import Supabase
import XCTest
@testable import Sakina

@MainActor
final class CompanionAccountTests: XCTestCase {
    private func makeAccount(handler: @escaping AuthRequestStub.Handler) -> CompanionAccount {
        let host = "auth-\(UUID().uuidString.lowercased()).example.test"
        AuthRequestStub.registry.set(handler, for: host)
        addTeardownBlock { AuthRequestStub.registry.remove(host) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthRequestStub.self]
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://\(host)")!, supabaseKey: "test-publishable-key",
            options: .init(auth: .init(storage: IsolatedAuthStorage(), autoRefreshToken: false,
                                      emitLocalSessionAsInitialSession: true),
                           global: .init(session: URLSession(configuration: configuration)))
        )
        // A successful action must update its UI before/without the asynchronous event listener.
        return CompanionAccount(client: client, observeAuthState: false)
    }

    func testEmailCodesAcceptArabicDigitsAndPastedSeparatorsButRejectOtherText() {
        XCTAssertEqual(CompanionAccount.normalizedEmailCode(" ١٢٣-٤٥٦\n"), "123456")
        XCTAssertEqual(CompanionAccount.normalizedEmailCode("۱۲۳۴۵۶۷۸"), "12345678")
        XCTAssertEqual(CompanionAccount.normalizedEmailCode("12 34 56 78"), "12345678")
        for invalid in ["", "12345", "12345678901", "12x3456", "abcdef", "²34567"] {
            XCTAssertNil(CompanionAccount.normalizedEmailCode(invalid), invalid)
        }
    }

    func testOverlappingEmailRequestsDoNotSendTwiceOrClearBusyEarly() async {
        let requested = expectation(description: "first email requested")
        let calls = LockedRequestCount()
        let account = makeAccount { _ in
            calls.increment()
            requested.fulfill()
            return .init(json: "{}", delay: 0.2)
        }
        let first = Task { await account.sendCode(email: "reader@example.com") }
        await fulfillment(of: [requested], timeout: 2)
        XCTAssertTrue(account.busy)
        let duplicate = await account.sendCode(email: "reader@example.com")
        XCTAssertFalse(duplicate)
        XCTAssertTrue(account.busy)
        let sent = await first.value
        XCTAssertTrue(sent)
        XCTAssertFalse(account.busy)
        XCTAssertEqual(calls.value, 1)
    }

    func testVerificationImmediatelyPublishesTheSessionAndNormalizedCode() async {
        let account = makeAccount { request in
            XCTAssertEqual(request.url?.path, "/auth/v1/verify")
            let body = try JSONSerialization.jsonObject(with: requestBody(request)) as? [String: Any]
            XCTAssertEqual(body?["token"] as? String, "123456")
            XCTAssertEqual(body?["email"] as? String, "reader@example.com")
            return .init(json: accountSessionJSON)
        }
        await account.verify(email: " reader@example.com ", code: "١٢٣ ٤٥٦")
        XCTAssertTrue(account.signedIn)
        XCTAssertEqual(account.email, "reader@example.com")
        XCTAssertFalse(account.busy)
        XCTAssertNil(account.message)
    }

    func testInvalidCodeDoesNotSendRequest() async {
        let account = makeAccount { _ in
            XCTFail("Malformed input must not call the backend")
            return .init(status: 500, json: "{}")
        }
        await account.verify(email: "reader@example.com", code: "12oops3456")
        XCTAssertFalse(account.signedIn)
        XCTAssertFalse(account.busy)
        XCTAssertNotNil(account.message)
    }

    func testAppleCancellationReleasesBusyWithoutPretendingToSignIn() async {
        let account = makeAccount { _ in
            XCTFail("Cancelled Apple authentication must not exchange a token")
            return .init(status: 500, json: "{}")
        }
        let request = ASAuthorizationAppleIDProvider().createRequest()
        account.prepareApple(request)
        XCTAssertTrue(account.busy)
        XCTAssertEqual(request.nonce?.count, 64)
        await account.completeApple(.failure(NSError(domain: ASAuthorizationError.errorDomain,
                                                    code: ASAuthorizationError.canceled.rawValue)))
        XCTAssertFalse(account.busy)
        XCTAssertFalse(account.signedIn)
        XCTAssertNil(account.message)
    }

    func testUnrelatedErrorWithApplesCancellationNumberIsNotSilenced() async {
        let account = makeAccount { _ in .init(json: "{}") }
        account.prepareApple(ASAuthorizationAppleIDProvider().createRequest())
        await account.completeApple(.failure(NSError(domain: "OtherProvider", code: ASAuthorizationError.canceled.rawValue)))
        XCTAssertFalse(account.busy)
        XCTAssertNotNil(account.message)
    }

    func testUnknownProviderErrorDoesNotExposeRawDiagnostics() async {
        let account = makeAccount { _ in
            .init(status: 400, json: #"{"code":"validation_failed","msg":"internal diagnostic secret-auth-code"}"#)
        }
        let sent = await account.sendCode(email: "reader@example.com")
        XCTAssertFalse(sent)
        XCTAssertNotNil(account.message)
        XCTAssertFalse(account.message?.contains("secret-auth-code") == true)
        XCTAssertFalse(account.busy)
    }

    func testInvalidCallbackDoesNotDisplayURLPayload() async {
        let account = makeAccount { _ in
            XCTFail("Malformed callback has no PKCE code to exchange")
            return .init(status: 400, json: "{}")
        }
        await account.handle(URL(string: "yaqeen://auth-callback?wrong=secret-auth-code")!)
        XCTAssertNotNil(account.message)
        XCTAssertFalse(account.message?.contains("secret-auth-code") == true)
        XCTAssertFalse(account.busy)
    }

    func testDeletionRequiresExplicitConfirmationFromTheServer() async {
        let account = makeAccount { request in
            switch request.url?.path {
            case "/auth/v1/verify": return .init(json: accountSessionJSON)
            case "/auth/v1/user": return .init(json: accountUserJSON)
            case "/functions/v1/delete-account": return .init(json: #"{"deleted":false}"#)
            default: XCTFail("Unexpected request"); return .init(status: 500, json: "{}")
            }
        }
        await account.verify(email: "reader@example.com", code: "123456")
        let deleted = await account.deleteAccount()
        XCTAssertFalse(deleted)
        XCTAssertTrue(account.signedIn)
        XCTAssertNotNil(account.message)
        XCTAssertFalse(account.busy)
    }

    func testConfirmedDeletionClearsLocalSessionEvenIfLogoutCannotReachServer() async {
        let account = makeAccount { request in
            switch request.url?.path {
            case "/auth/v1/verify": return .init(json: accountSessionJSON)
            case "/auth/v1/user": return .init(json: accountUserJSON)
            case "/functions/v1/delete-account":
                let body = try JSONSerialization.jsonObject(with: requestBody(request)) as? [String: String]
                XCTAssertEqual(body?["reason"], "")
                XCTAssertEqual(body?["feedback"], "")
                return .init(json: #"{"deleted":true}"#)
            case "/auth/v1/logout": throw URLError(.notConnectedToInternet)
            default: XCTFail("Unexpected request"); return .init(status: 500, json: "{}")
            }
        }
        await account.verify(email: "reader@example.com", code: "123456")
        let deleted = await account.deleteAccount()
        XCTAssertTrue(deleted)
        XCTAssertFalse(account.signedIn)
        XCTAssertNil(account.email)
        XCTAssertNil(account.message)
        XCTAssertFalse(account.busy)
    }
}

private let accountUserJSON = #"{"id":"C1130E8F-EC6A-4926-8B24-E2D6A2127E44","aud":"authenticated","email":"reader@example.com","app_metadata":{},"user_metadata":{},"created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z","identities":[],"is_anonymous":false}"#
private var accountSessionJSON: String {
    "{\"access_token\":\"test-session-token\",\"token_type\":\"bearer\",\"expires_in\":3600,\"expires_at\":\(Date().timeIntervalSince1970 + 3600),\"refresh_token\":\"test-refresh-token\",\"user\":\(accountUserJSON)}"
}

private func requestBody(_ request: URLRequest) -> Data {
    if let data = request.httpBody { return data }
    guard let stream = request.httpBodyStream else { return Data() }
    stream.open()
    defer { stream.close() }
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)
    while stream.hasBytesAvailable {
        let count = stream.read(&buffer, maxLength: buffer.count)
        guard count > 0 else { break }
        data.append(buffer, count: count)
    }
    return data
}

private final class IsolatedAuthStorage: AuthLocalStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Data] = [:]
    func store(key: String, value: Data) { lock.lock(); defer { lock.unlock() }; values[key] = value }
    func retrieve(key: String) -> Data? { lock.lock(); defer { lock.unlock() }; return values[key] }
    func remove(key: String) { lock.lock(); defer { lock.unlock() }; values.removeValue(forKey: key) }
}

private final class LockedRequestCount: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
    func increment() { lock.lock(); defer { lock.unlock() }; count += 1 }
}

private final class AuthRequestStub: URLProtocol, @unchecked Sendable {
    struct Response: Sendable {
        var status = 200
        var json: String
        var delay: TimeInterval = 0
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
                client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: response.status,
                                                                    httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                                    cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: Data(response.json.utf8))
                client?.urlProtocolDidFinishLoading(self)
            }
            if response.delay > 0 { DispatchQueue.global().asyncAfter(deadline: .now() + response.delay, execute: deliver) }
            else { deliver() }
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}
