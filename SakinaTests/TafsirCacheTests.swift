import XCTest
@testable import Sakina

@MainActor
final class TafsirCacheTests: XCTestCase {
    private var root: URL!
    private var clock: TestClock!
    private var session: URLSession!

    override func setUp() async throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        clock = TestClock()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TafsirRequestStub.self]
        configuration.urlCache = nil
        session = URLSession(configuration: configuration)
        TafsirRequestStub.reset()
    }

    override func tearDown() async throws {
        session.invalidateAndCancel()
        try? FileManager.default.removeItem(at: root)
        session = nil
        root = nil
        clock = nil
    }

    func testFreshMemoryAndDiskCacheAvoidAnotherNetworkRequest() async throws {
        let service = makeService()
        let first = try await service.tafsir(for: "2:255", edition: .ibnKathirEnglish)
        XCTAssertEqual(first, "Response 1")
        clock.date.addTimeInterval(TafsirService.maximumCacheAge - 1)
        let memory = try await service.tafsir(for: "2:255", edition: .ibnKathirEnglish)
        let disk = try await makeService().tafsir(for: "2:255", edition: .ibnKathirEnglish)
        XCTAssertEqual(memory, first)
        XCTAssertEqual(disk, first)
        XCTAssertEqual(TafsirRequestStub.count, 1)
    }

    func testReadingCacheDoesNotExtendItsLifetimeAndExpiredEntryRefreshes() async throws {
        let service = makeService()
        _ = try await service.tafsir(for: "2:255", edition: .ibnKathirEnglish)
        clock.date.addTimeInterval(TafsirService.maximumCacheAge - 1)
        XCTAssertNotNil(service.cached(for: "2:255", edition: .ibnKathirEnglish))
        clock.date.addTimeInterval(1)
        XCTAssertNil(service.cached(for: "2:255", edition: .ibnKathirEnglish))
        let refreshed = try await service.tafsir(for: "2:255", edition: .ibnKathirEnglish)
        XCTAssertEqual(refreshed, "Response 2")
        XCTAssertEqual(TafsirRequestStub.count, 2)
        XCTAssertEqual(TafsirRequestStub.lastCachePolicy, .reloadIgnoringLocalCacheData)
    }

    func testRelaunchRemovesExpiredAndLegacyFilesWithoutResettingTheirAge() async throws {
        let service = makeService()
        _ = try await service.tafsir(for: "2:255", edition: .ibnKathirEnglish)
        let legacy = root.appendingPathComponent("16/1-1.txt")
        try FileManager.default.createDirectory(at: legacy.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "Undated legacy content".write(to: legacy, atomically: true, encoding: .utf8)
        clock.date.addTimeInterval(TafsirService.maximumCacheAge)
        let relaunched = makeService()
        XCTAssertNil(relaunched.cached(for: "2:255", edition: .ibnKathirEnglish))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("169/2-255.json").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacy.path))
    }

    func testExpiredContentIsNotServedWhenRefreshFailsOffline() async throws {
        let service = makeService()
        _ = try await service.tafsir(for: "2:255", edition: .ibnKathirEnglish)
        clock.date.addTimeInterval(TafsirService.maximumCacheAge)
        TafsirRequestStub.setOffline()
        do {
            _ = try await service.tafsir(for: "2:255", edition: .ibnKathirEnglish)
            XCTFail("An expired cache must not mask the failed refresh")
        } catch {
            XCTAssertEqual(error as? TafsirService.Failure, .offline)
        }
        XCTAssertNil(service.cached(for: "2:255", edition: .ibnKathirEnglish))
    }

    func testFutureFetchTimestampIsNotTreatedAsFresh() async throws {
        let service = makeService()
        _ = try await service.tafsir(for: "2:255", edition: .ibnKathirEnglish)
        clock.date.addTimeInterval(-1)
        XCTAssertNil(service.cached(for: "2:255", edition: .ibnKathirEnglish))
    }

    private func makeService() -> TafsirService {
        TafsirService(session: session, cacheRoot: root, now: { [clock] in clock!.date })
    }
}

@MainActor
private final class TestClock {
    var date = Date(timeIntervalSince1970: 1_800_000_000)
}

private final class TafsirRequestStub: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    private static var requestCount = 0
    private static var offline = false
    private static var cachePolicy: URLRequest.CachePolicy?
    static var count: Int { lock.lock(); defer { lock.unlock() }; return requestCount }
    static var lastCachePolicy: URLRequest.CachePolicy? { lock.lock(); defer { lock.unlock() }; return cachePolicy }
    static func reset() { lock.lock(); defer { lock.unlock() }; requestCount = 0; offline = false; cachePolicy = nil }
    static func setOffline() { lock.lock(); defer { lock.unlock() }; offline = true }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        Self.requestCount += 1
        let index = Self.requestCount
        let offline = Self.offline
        Self.cachePolicy = request.cachePolicy
        Self.lock.unlock()
        if offline {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("{\"tafsir\":{\"text\":\"<p>Response \(index)</p>\"}}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
