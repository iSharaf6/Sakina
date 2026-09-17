import Foundation
import SwiftData
import Supabase
import XCTest
@testable import Sakina

@MainActor
final class AccountLibrarySyncTests: XCTestCase {
    func testLegacyImportPreservesAyahNotesSavedMomentsAndReflections() async throws {
        let f = try Fixture()
        f.library.setNote("For my family", for: "1:1")
        f.context.insert(Bookmark(situationID: "beforeMarriage"))
        f.context.insert(JournalEntry(situationID: "beforeMarriage", text: "A private reflection"))
        let account = try await makeAccount()
        await f.sync.activate(account: account, context: f.context)
        XCTAssertTrue(f.sync.needsImportChoice)
        XCTAssertTrue(f.sync.hasPreviousDeviceLibrary)
        XCTAssertTrue(f.library.marks.isEmpty, "Legacy content must stay hidden before choosing its account")
        await f.sync.resolveLegacyImport(include: true)
        XCTAssertEqual(f.library.note("1:1"), "For my family")
        XCTAssertEqual(try f.context.fetchCount(FetchDescriptor<Bookmark>()), 1)
        XCTAssertEqual(try f.context.fetch(FetchDescriptor<JournalEntry>()).first?.text, "A private reflection")
        XCTAssertFalse(f.sync.hasPendingChanges)
    }

    func testSwitchingFromAToBAndBackKeepsSeparateLibraries() async throws {
        let f = try Fixture(), a = try await makeAccount(), b = try await makeAccount()
        await f.open(a)
        f.library.setNote("A only", for: "1:1")
        try f.sync.checkpoint()
        await f.open(b)
        XCTAssertNil(f.library.mark("1:1"))
        f.library.setNote("B only", for: "2:1")
        try f.sync.checkpoint()
        await f.sync.activate(account: a, context: f.context)
        XCTAssertEqual(f.library.note("1:1"), "A only")
        XCTAssertNil(f.library.mark("2:1"))
        await f.sync.activate(account: b, context: f.context)
        XCTAssertEqual(f.library.note("2:1"), "B only")
        XCTAssertNil(f.library.mark("1:1"))
    }

    func testOfflineOutboxSurvivesCoordinatorRecreationAndLaterSync() async throws {
        let f = try Fixture(), account = try await makeAccount()
        await f.remote(for: account).setOffline(true)
        await f.open(account)
        f.library.setNote("Saved while offline", for: "1:1")
        try f.sync.checkpoint()
        XCTAssertTrue(f.sync.hasPendingChanges)
        f.recreateCoordinator()
        await f.sync.activate(account: account, context: f.context)
        XCTAssertEqual(f.library.note("1:1"), "Saved while offline")
        XCTAssertTrue(f.sync.hasPendingChanges)
        await f.remote(for: account).setOffline(false)
        await f.sync.syncNow()
        XCTAssertFalse(f.sync.hasPendingChanges)
        let cloud = await f.remote(for: account).snapshot()
        XCTAssertNotNil(cloud.payload["ayah/1:1"])
    }

    func testRemoteDeletionAndIndependentEditsMergeWithoutResurrection() async throws {
        let f = try Fixture(), account = try await makeAccount()
        await f.open(account)
        f.library.setNote("Remove on other phone", for: "1:1")
        await f.sync.syncNow()
        var remoteMark = AyahMark(key: "2:1")
        remoteMark.note = "Other phone"
        await f.remote(for: account).replace(["ayah/2:1": try AccountLibraryProjection.encode(remoteMark)])
        f.library.setNote("This phone", for: "3:1")
        await f.sync.syncNow()
        XCTAssertNil(f.library.mark("1:1"))
        XCTAssertEqual(f.library.note("2:1"), "Other phone")
        XCTAssertEqual(f.library.note("3:1"), "This phone")
    }

    func testEditsDuringAnUploadRemainPendingAndAreNotOverwritten() async throws {
        let f = try Fixture(), account = try await makeAccount()
        await f.open(account)
        f.library.setNote("First edit", for: "1:1")
        let entered = expectation(description: "Write suspended")
        await f.remote(for: account).pauseNextWrite { entered.fulfill() }
        let uploading = Task { await f.sync.syncNow() }
        await fulfillment(of: [entered], timeout: 2)
        f.library.setNote("Edited again during upload", for: "1:1")
        await f.remote(for: account).resumeWrite()
        await uploading.value
        XCTAssertEqual(f.library.note("1:1"), "Edited again during upload")
        XCTAssertTrue(f.sync.hasPendingChanges)
        await f.sync.syncNow()
        XCTAssertFalse(f.sync.hasPendingChanges)
        let snapshot = await f.remote(for: account).snapshot()
        let value = try XCTUnwrap(snapshot.payload["ayah/1:1"])
        XCTAssertEqual(try AccountLibraryProjection.decode(AyahMark.self, value).note, "Edited again during upload")
    }

    func testMalformedCloudRecordPreservesLocalLibraryAndLastGoodEnvelope() async throws {
        let f = try Fixture(), account = try await makeAccount()
        await f.open(account)
        f.library.setNote("Keep my note", for: "1:1")
        try f.sync.checkpoint()
        let before = try Data(contentsOf: f.envelopeURL(account))
        await f.remote(for: account).replace(["ayah/2:1": "not valid JSON"])
        await f.sync.syncNow()
        XCTAssertEqual(f.library.note("1:1"), "Keep my note")
        XCTAssertEqual(try Data(contentsOf: f.envelopeURL(account)), before)
        XCTAssertTrue(f.sync.hasPendingChanges)
        XCTAssertNotNil(f.sync.statusMessage)
    }

    func testStorageFailureAfterCloudCommitDoesNotAcknowledgePendingEdits() async throws {
        let f = try Fixture(), account = try await makeAccount()
        await f.open(account)
        f.library.setNote("Do not lose pending changes", for: "1:1")
        try f.sync.checkpoint()
        let file = f.envelopeURL(account), backup = try Data(contentsOf: f.envelopeURL(account))
        let entered = expectation(description: "Write suspended before acknowledgement")
        await f.remote(for: account).pauseNextWrite { entered.fulfill() }
        let uploading = Task { await f.sync.syncNow() }
        await fulfillment(of: [entered], timeout: 2)
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
        await f.remote(for: account).resumeWrite()
        await uploading.value
        XCTAssertTrue(f.sync.hasPendingChanges)
        XCTAssertEqual(f.library.note("1:1"), "Do not lose pending changes")
        XCTAssertNotNil(f.sync.statusMessage)
        try FileManager.default.removeItem(at: file)
        try backup.write(to: file)
    }

    func testDeletingAnAccountErasesOnlyItsOwnCache() async throws {
        let f = try Fixture(), a = try await makeAccount(), b = try await makeAccount()
        await f.open(a)
        f.library.setNote("A", for: "1:1")
        try f.sync.checkpoint()
        await f.open(b)
        f.library.setNote("B", for: "2:1")
        try f.sync.checkpoint()
        await f.sync.eraseDeletedAccount(a.userID!)
        XCTAssertFalse(FileManager.default.fileExists(atPath: f.envelopeURL(a).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: f.envelopeURL(b).path))
        XCTAssertEqual(f.library.note("2:1"), "B")
        XCTAssertEqual(f.sync.currentUserID, b.userID)
    }

    func testAyahPersistenceFailureDoesNotPublishAnotherAccountsProjection() throws {
        let f = try Fixture()
        f.library.setNote("Original owner", for: "1:1")
        f.library.saveNow()
        try FileManager.default.removeItem(at: f.ayahURL)
        try FileManager.default.createDirectory(at: f.ayahURL, withIntermediateDirectories: true)
        var mark = AyahMark(key: "2:1")
        mark.note = "Other owner"
        let projection = AccountLibraryProjection(context: f.context, library: f.library, defaults: f.defaults)
        XCTAssertThrowsError(try projection.apply(["ayah/2:1": AccountLibraryProjection.encode(mark)]))
        XCTAssertEqual(f.library.note("1:1"), "Original owner")
        XCTAssertNil(f.library.mark("2:1"))
    }

    private func makeAccount() async throws -> CompanionAccount {
        let user = UUID(), host = "sync-\(UUID().uuidString.lowercased()).example.test"
        CloudLibraryRequestStub.registry.set({ request in
            if request.url?.path == "/auth/v1/logout" { return .init(json: "{}") }
            return .init(json: cloudTestSessionJSON.replacingOccurrences(of: cloudTestUserID.uuidString, with: user.uuidString))
        }, for: host)
        addTeardownBlock { CloudLibraryRequestStub.registry.remove(host) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CloudLibraryRequestStub.self]
        let client = SupabaseClient(supabaseURL: URL(string: "https://\(host)")!, supabaseKey: "test-key",
            options: .init(auth: .init(storage: CloudLibraryAuthStorage(), autoRefreshToken: false,
                                      emitLocalSessionAsInitialSession: true),
                           global: .init(session: URLSession(configuration: configuration))))
        let account = CompanionAccount(client: client, observeAuthState: false)
        await account.verify(email: "reader@example.test", code: "123456")
        XCTAssertEqual(account.userID, user)
        return account
    }

    @MainActor private final class Fixture {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("library-sync-\(UUID())")
        let defaults: UserDefaults
        let suite = "library-sync-\(UUID())"
        let container: ModelContainer
        let library: AyahLibrary
        var context: ModelContext { container.mainContext }
        var directory: URL { root.appendingPathComponent("Accounts") }
        var ayahURL: URL { root.appendingPathComponent("ayahs.json") }
        var remotes: [UUID: MemoryCloudLibrary] = [:]
        var sync: AccountLibrarySync!
        init() throws {
            defaults = UserDefaults(suiteName: suite)!
            container = try ModelContainer(for: Bookmark.self, JournalEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            library = AyahLibrary(fileURL: root.appendingPathComponent("ayahs.json"), defaults: defaults)
            recreateCoordinator()
        }
        func remote(for account: CompanionAccount) -> MemoryCloudLibrary {
            let id = account.userID!
            if let remote = remotes[id] { return remote }
            let remote = MemoryCloudLibrary()
            remotes[id] = remote
            return remote
        }
        func recreateCoordinator() {
            sync = AccountLibrarySync(directory: directory, defaults: defaults, library: library) { [weak self] _, id in
                guard let self else { return MemoryCloudLibrary() }
                if let remote = self.remotes[id] { return remote }
                let remote = MemoryCloudLibrary()
                self.remotes[id] = remote
                return remote
            }
        }
        func open(_ account: CompanionAccount) async {
            await sync.activate(account: account, context: context)
            if sync.needsImportChoice { await sync.resolveLegacyImport(include: false) }
        }
        func envelopeURL(_ account: CompanionAccount) -> URL {
            directory.appendingPathComponent("\(account.userID!.uuidString).json")
        }
        deinit {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: root)
        }
    }
}

private actor MemoryCloudLibrary: CloudLibraryRemote {
    private var document = CloudLibrarySnapshot(revision: 0, payload: [:])
    private var offline = false
    private var onWrite: (@Sendable () -> Void)?
    private var writeContinuation: CheckedContinuation<Void, Never>?
    func setOffline(_ value: Bool) { offline = value }
    func snapshot() -> CloudLibrarySnapshot { document }
    func replace(_ payload: [String: String]) { document = .init(revision: document.revision + 1, payload: payload) }
    func pauseNextWrite(_ callback: @escaping @Sendable () -> Void) { onWrite = callback }
    func resumeWrite() { writeContinuation?.resume(); writeContinuation = nil }
    func fetch() async throws -> CloudLibrarySnapshot {
        if offline { throw URLError(.notConnectedToInternet) }
        return document
    }
    func compareAndSwap(payload: [String: String], expectedRevision: Int64) async throws -> CloudLibrarySnapshot? {
        if offline { throw URLError(.notConnectedToInternet) }
        if let callback = onWrite {
            onWrite = nil
            await withCheckedContinuation { continuation in
                writeContinuation = continuation
                callback()
            }
        }
        guard document.revision == expectedRevision else { return nil }
        document = .init(revision: expectedRevision + 1, payload: payload)
        return document
    }
}
