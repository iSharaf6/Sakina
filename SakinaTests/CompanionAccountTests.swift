import AuthenticationServices
import Supabase
import SwiftData
import SwiftUI
import UIKit
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

    func testProviderNameIsDisplayedAndClearedWhenSigningOut() async {
        let account = makeAccount { request in
            if request.url?.path == "/auth/v1/logout" { return .init(json: "{}") }
            return .init(json: accountSessionJSON.replacingOccurrences(
                of: #""user_metadata":{}"#, with: #""user_metadata":{"full_name":"  ليلى أحمد  "}"#))
        }
        await account.verify(email: "reader@example.com", code: "123456")
        XCTAssertEqual(account.displayName, "ليلى أحمد")
        await account.signOut()
        XCTAssertNil(account.displayName)
        XCTAssertFalse(account.signedIn)
    }

    /// One mounted hub observes both Auth and SwiftData without relying on
    /// production credentials, network services or pixel-position assertions.
    func testPersonalHubObservesLocalLibraryLanguageAndSignOut() async throws {
        let defaults = UserDefaults.standard
        let previousLanguage = defaults.object(forKey: SettingsKeys.appLanguage)
        defaults.set(AppLanguage.english.rawValue, forKey: SettingsKeys.appLanguage)
        defer {
            if let previousLanguage { defaults.set(previousLanguage, forKey: SettingsKeys.appLanguage) }
            else { defaults.removeObject(forKey: SettingsKeys.appLanguage) }
        }
        let account = makeAccount { request in
            switch request.url?.path {
            case "/auth/v1/verify":
                return .init(json: accountSessionJSON.replacingOccurrences(
                    of: #""user_metadata":{}"#, with: #""user_metadata":{"full_name":"Layla Ahmed"}"#))
            case "/auth/v1/logout": return .init(json: "{}")
            default:
                XCTFail("The personal hub must not make a new backend request just to render")
                return .init(status: 500, json: "{}")
            }
        }
        await account.verify(email: "reader@example.com", code: "123456")
        XCTAssertTrue(account.signedIn)

        let container = try ModelContainer(for: Bookmark.self, JournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        container.mainContext.insert(Bookmark(situationID: "beforeMarriage"))
        container.mainContext.insert(JournalEntry(situationID: "beforeMarriage", text: "A private test reflection."))
        try container.mainContext.save()
        let scholar = ScholarContentStore(client: nil, cache: ScholarContentCache(fileURL: nil))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let host = UIHostingController(rootView: PersonalHubHarness(account: account)
            .modelContainer(container).environmentObject(scholar))
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousWindow?.makeKeyAndVisible()
        }
        // Capture the actual mounted screen before inspecting the virtual AX
        // tree, so a failed assertion still leaves useful rendering evidence.
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(200))
        try attachHubScreenshot(host, name: "Account-Initial-English-Dark-SignedIn")

        // SwiftUI's virtual nodes expose their labels through public in-process
        // AX APIs, but not UIAccessibilityIdentification protocol conformance.
        // Exact labels are scoped to this hosting controller's mounted tree.
        guard await waitForHub(in: host, description: "English signed-in identity", condition: { elements in
            elements.contains { $0.label == "Layla Ahmed" }
                && elements.contains { $0.label == "reader@example.com" }
        }) else { return }
        guard await waitForHub(in: host, description: "SwiftData saved moment", condition: { elements in
            elements.contains { $0.label == "Saved moments, 1. Readings to return to" }
        }) else { return }
        container.mainContext.insert(Bookmark(situationID: "lookingForSpouse"))
        try container.mainContext.save()
        guard await waitForHub(in: host, description: "Live SwiftData count update", condition: { elements in
            elements.contains { $0.label == "Saved moments, 2. Readings to return to" }
        }) else { return }
        try attachHubScreenshot(host, name: "Account-English-Dark-SignedIn")

        defaults.set(AppLanguage.arabic.rawValue, forKey: SettingsKeys.appLanguage)
        let arabicCount = 2.formatted(.number.locale(AppLanguage.arabic.locale))
        let arabicSavedLabel = "مواقف محفوظة, \(arabicCount). قراءات تعود إليها"
        guard await waitForHub(in: host, description: "Arabic hub labels", condition: { elements in
            elements.contains { $0.label == arabicSavedLabel }
                && elements.contains { $0.label == "reader@example.com" }
        }) else { return }
        try attachHubScreenshot(host, name: "Account-Arabic-RTL-Dark-SignedIn")

        // Sign out through the same Auth instance while the existing view is
        // mounted: a one-time state snapshot cannot satisfy these checks.
        await account.signOut()
        XCTAssertFalse(account.signedIn)
        guard await waitForHub(in: host, description: "Guest hub after sign-out", condition: { elements in
            elements.contains { $0.label == "أهلًا بك في مساحتك" }
                && !elements.contains { $0.label == "reader@example.com" }
                && elements.contains { $0.label == arabicSavedLabel }
        }) else { return }
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Bookmark>()), 2,
                       "Signing out must preserve the separate local library")
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<JournalEntry>()), 1)
        try attachHubScreenshot(host, name: "Account-Arabic-RTL-Dark-Guest")
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
    private struct HubAccessibilityElement {
        let identifier: String?
        let label: String
        let typeName: String
        let frame: CGRect
    }

    /// Uses public accessibility-container APIs, including SwiftUI's virtual
    /// elements, rather than depending on its private hosting-view hierarchy.
    private func hubAccessibility(in root: UIView) -> [HubAccessibilityElement] {
        var visited = Set<ObjectIdentifier>()
        var retained: [NSObject] = []
        var result: [HubAccessibilityElement] = []
        func visit(_ object: NSObject, depth: Int) {
            guard depth < 30, visited.count < 2_000,
                  visited.insert(ObjectIdentifier(object)).inserted else { return }
            retained.append(object)
            result.append(.init(identifier: (object as? UIAccessibilityIdentification)?.accessibilityIdentifier,
                                // SwiftUI adds bidi isolation around interpolated Arabic
                                // labels. Ignore only those invisible test-comparison marks.
                                label: String(String.UnicodeScalarView((object.accessibilityLabel ?? "").unicodeScalars.filter {
                                    ![0x2066, 0x2067, 0x2068, 0x2069].contains($0.value)
                                })),
                                typeName: NSStringFromClass(type(of: object)),
                                frame: object.accessibilityFrame))
            if let view = object as? UIView {
                for child in view.subviews { visit(child, depth: depth + 1) }
            }
            let elements = object.accessibilityElements
            if let elements {
                for case let child as NSObject in elements { visit(child, depth: depth + 1) }
            } else {
                let count = object.accessibilityElementCount()
                if count > 0 && count < 500 {
                    for index in 0..<count {
                        if let child = object.accessibilityElement(at: index) as? NSObject {
                            visit(child, depth: depth + 1)
                        }
                    }
                }
            }
        }
        visit(root, depth: 0)
        return result
    }

    private func waitForHub(in host: UIViewController, description: String,
                            condition: ([HubAccessibilityElement]) -> Bool) async -> Bool {
        var elements: [HubAccessibilityElement] = []
        for _ in 0..<150 {
            host.view.layoutIfNeeded()
            elements = hubAccessibility(in: host.view)
            if condition(elements) { return true }
            do { try await Task.sleep(for: .milliseconds(20)) }
            catch { break }
        }
        let diagnostic = "Mounted: \(host.view.window != nil), bounds: \(host.view.bounds)\n"
            + elements.map {
                "\($0.typeName) id=\($0.identifier ?? "nil") label=\($0.label.debugDescription) frame=\($0.frame)"
            }.joined(separator: "\n")
        let attachment = XCTAttachment(string: diagnostic)
        attachment.name = "Account-AX-\(description)"
        attachment.lifetime = .keepAlways
        add(attachment)
        try? attachHubScreenshot(host, name: "Account-Failure-\(description)")
        XCTFail("Personal hub did not render \(description). Mounted=\(host.view.window != nil), "
                + "AX elements=\(elements.count); see Account-AX and Account-Failure attachments.")
        // The assertion records the failure; return normally instead of throwing
        // while UIKit is tearing down a mounted navigation hierarchy.
        return false
    }

    private func attachHubScreenshot(_ host: UIViewController, name: String) throws {
        host.view.layoutIfNeeded()
        let bounds = host.view.bounds
        XCTAssertGreaterThan(bounds.width, 0)
        XCTAssertGreaterThan(bounds.height, 0)
        let image = UIGraphicsImageRenderer(bounds: bounds).image { _ in
            _ = host.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private struct PersonalHubHarness: View {
        let account: CompanionAccount
        @AppStorage(SettingsKeys.appLanguage) private var languageRaw = AppLanguage.english.rawValue
        private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .english }

        var body: some View {
            NavigationStack { CompanionAccountView(account: account) }
                .yaqeenLanguage(language)
                .preferredColorScheme(.dark)
                .transaction { $0.disablesAnimations = true }
        }
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
