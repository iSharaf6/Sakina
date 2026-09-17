import Combine
import Foundation
import SwiftData
import SwiftUI
import Supabase

/// Durable, account-scoped outbox. A failed request never discards local edits;
/// compare-and-swap prevents one device from replacing another device's library.
@MainActor
final class AccountLibrarySync: ObservableObject {
    static let shared = AccountLibrarySync()
    @Published private(set) var isPreparing = true
    @Published private(set) var needsImportChoice = false
    @Published private(set) var isSyncing = false
    @Published private(set) var hasPendingChanges = false
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var statusMessage: String?
    @Published private(set) var currentUserID: UUID?
    var canUseLibrary: Bool { currentUserID != nil && !isPreparing && !needsImportChoice && projection != nil }

    struct Envelope: Codable {
        var values: [String: String] = [:]
        var lastProjection: [String: String] = [:]
        var pending: [String: CloudLibraryChange] = [:]
        var lastSyncedAt: Date?
    }

    private let directory: URL
    private let defaults: UserDefaults
    private let library: AyahLibrary
    private let makeRemote: (SupabaseClient, UUID) -> any CloudLibraryRemote
    private var envelope = Envelope()
    private var projection: AccountLibraryProjection?
    private var account: CompanionAccount?
    private var remote: (any CloudLibraryRemote)?
    private var generation = UUID()
    private var loop: Task<Void, Never>?
    private var observers: Set<AnyCancellable> = []
    private var lastAttempt = Date.distantPast
    private var legacy: [String: String]?
    private static let ownerKey = "haneen.library.activeOwner"
    private static let legacyClaimKey = "haneen.library.legacyClaim"
    private var copy: AppCopy {
        AppCopy(language: AppLanguage(rawValue: defaults.string(forKey: SettingsKeys.appLanguage) ?? "") ?? .english)
    }

    init(directory: URL? = nil, defaults: UserDefaults = .standard, library: AyahLibrary? = nil,
         makeRemote: @escaping (SupabaseClient, UUID) -> any CloudLibraryRemote = { SupabaseCloudLibraryRemote(client: $0, userID: $1) }) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("AccountLibraries", isDirectory: true)
        self.defaults = defaults
        self.library = library ?? .shared
        self.makeRemote = makeRemote
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    do { try self?.checkpoint() } catch { self?.showStorageError() }
                }
            }.store(in: &observers)
    }

    deinit { loop?.cancel() }

    func activate(account: CompanionAccount, context: ModelContext) async {
        let target = account.userID
        if target == currentUserID, projection != nil, !isPreparing { return }
        // Invalidate old network responses before switching the visible store.
        generation = UUID()
        loop?.cancel()
        loop = nil
        isSyncing = false
        isPreparing = true
        needsImportChoice = false
        statusMessage = nil
        do {
            if currentUserID != nil { try checkpoint() }
            let local = AccountLibraryProjection(context: context, library: library, defaults: defaults)
            self.projection = local
            self.account = account
            remote = nil
            let activeOwner = defaults.string(forKey: Self.ownerKey)
            if activeOwner == nil, !FileManager.default.fileExists(atPath: legacyURL.path) {
                // Preserve the old guest library before any account becomes active.
                try write(try local.capture(), to: legacyURL)
            } else if let previous = activeOwner.flatMap(UUID.init(uuidString:)), previous != currentUserID {
                // Recover edits made immediately before termination, before a polling checkpoint.
                var saved = try readEnvelope(previous) ?? Envelope()
                let captured = try local.capture()
                record(captured, in: &saved)
                try write(saved, to: fileURL(previous))
            }
            if target == nil {
                defaults.set("switching", forKey: Self.ownerKey)
                try local.apply([:])
                defaults.set("signed-out", forKey: Self.ownerKey)
                currentUserID = nil
                envelope = Envelope()
                refreshStatus()
                isPreparing = false
                return
            }
            let userID = target!
            currentUserID = userID
            guard let client = account.client else { throw SyncError.unavailable }
            remote = makeRemote(client, userID)
            if let cached = try readEnvelope(userID) {
                envelope = cached
                defaults.set("switching", forKey: Self.ownerKey)
                try local.apply(cached.values)
                envelope.lastProjection = try local.capture()
                try persist()
                defaults.set(userID.uuidString, forKey: Self.ownerKey)
                refreshStatus()
                isPreparing = false
                startLoop()
                await syncNow()
            } else {
                envelope = Envelope()
                // Never show the last person's library beneath a new person's identity.
                defaults.set("switching", forKey: Self.ownerKey)
                try local.apply([:])
                defaults.set("signed-out", forKey: Self.ownerKey)
                legacy = defaults.string(forKey: Self.legacyClaimKey) == nil ? try read([String: String].self, at: legacyURL) : nil
                needsImportChoice = true
                isPreparing = false
                refreshStatus()
            }
        } catch {
            // Fail closed on corrupt storage or an unsuccessful account switch.
            statusMessage = copy("Your library could not be opened safely. Please try again. Your saved copy has not been removed.", "تعذّر فتح مكتبتك بأمان. حاول مرة أخرى. لم تُحذف نسختك المحفوظة.")
            isPreparing = true
        }
    }

    var hasPreviousDeviceLibrary: Bool { !(legacy ?? [:]).isEmpty }

    func resolveLegacyImport(include: Bool) async {
        guard needsImportChoice, let userID = currentUserID, account?.userID == userID, let projection else { return }
        do {
            envelope = Envelope()
            let initial = include ? (legacy ?? [:]) : [:]
            record(initial, in: &envelope)
            // Save before projecting so a crash can always recover the initial choice.
            try persist()
            try projection.apply(initial)
            envelope.lastProjection = try projection.capture()
            try persist()
            defaults.set(userID.uuidString, forKey: Self.ownerKey)
            if include, legacy != nil { defaults.set(userID.uuidString, forKey: Self.legacyClaimKey) }
            legacy = nil
            needsImportChoice = false
            isPreparing = false
            refreshStatus()
            startLoop()
            await syncNow()
        } catch { showStorageError() }
    }

    func checkpoint() throws {
        guard let userID = currentUserID, let projection, !needsImportChoice,
              defaults.string(forKey: Self.ownerKey) == userID.uuidString else { return }
        let captured = try projection.capture()
        if captured != envelope.lastProjection {
            var next = envelope
            record(captured, in: &next)
            try write(next, to: fileURL(userID))
            envelope = next
            refreshStatus()
        }
    }

    func syncNow() async {
        guard canUseLibrary, !isSyncing, let userID = currentUserID,
              account?.userID == userID, let remote, let projection else { return }
        let operation = generation
        isSyncing = true
        lastAttempt = .now
        defer { if operation == generation { isSyncing = false } }
        do {
            try checkpoint()
            // Retry a compare-and-swap race against a fresh cloud snapshot.
            for _ in 0..<4 {
                let cloud = try await remote.fetch()
                guard valid(operation, userID) else { return }
                try checkpoint()
                let sent = envelope.pending
                let merged = CloudLibraryMerge.applying(changes: sent, to: cloud.payload)
                try projection.validate(merged)
                let saved: CloudLibrarySnapshot
                if merged == cloud.payload { saved = cloud }
                else {
                    guard let committed = try await remote.compareAndSwap(payload: merged, expectedRevision: cloud.revision) else { continue }
                    saved = committed
                }
                guard valid(operation, userID) else { return }
                // Keep edits made while the request was in flight. Only acknowledge
                // outbox entries whose exact value was included in this commit.
                try checkpoint()
                var next = envelope
                for (key, change) in sent where next.pending[key] == change { next.pending.removeValue(forKey: key) }
                next.values = CloudLibraryMerge.applying(changes: next.pending, to: saved.payload)
                try projection.validate(next.values)
                // Persist a recovery journal before projecting across the two local
                // stores. A crash during restoration must not reclassify a partial
                // projection as this device's edits on the next launch.
                do {
                    try write(next, to: fileURL(userID))
                    defaults.set("restoring", forKey: Self.ownerKey)
                    try projection.apply(next.values)
                    next.lastProjection = try projection.capture()
                    next.lastSyncedAt = .now
                    try write(next, to: fileURL(userID))
                } catch { isPreparing = true; throw error }
                envelope = next
                defaults.set(userID.uuidString, forKey: Self.ownerKey)
                statusMessage = nil
                refreshStatus()
                return
            }
            throw SyncError.contended
        } catch {
            guard valid(operation, userID) else { return }
            statusMessage = copy("Saved on this iPhone. Cloud sync will retry when a connection is available.", "محفوظة على هذا الهاتف. ستُعاد محاولة المزامنة السحابية عند توفر الاتصال.")
            refreshStatus()
        }
    }

    /// Called only after the authenticated deletion endpoint confirms success.
    func eraseDeletedAccount(_ userID: UUID) async {
        generation = UUID()
        loop?.cancel()
        loop = nil
        isSyncing = false
        if currentUserID == userID { defaults.set("signed-out", forKey: Self.ownerKey) }
        do {
            let file = fileURL(userID)
            if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
            if defaults.string(forKey: Self.legacyClaimKey) == userID.uuidString {
                if FileManager.default.fileExists(atPath: legacyURL.path) { try FileManager.default.removeItem(at: legacyURL) }
                defaults.removeObject(forKey: Self.legacyClaimKey)
            }
            if currentUserID == userID {
                try projection?.apply([:])
                envelope = Envelope()
                currentUserID = nil
                remote = nil
                defaults.set("signed-out", forKey: Self.ownerKey)
                refreshStatus()
                isPreparing = true
            }
        } catch {
            // Keep the gate closed even if the filesystem cannot be written.
            currentUserID = nil
            isPreparing = true
            showStorageError()
        }
    }

    private func startLoop() {
        loop?.cancel()
        let operation = generation
        loop = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                guard let self, self.generation == operation else { return }
                guard UIApplication.shared.applicationState != .background else { continue }
                do { try self.checkpoint() } catch { self.showStorageError(); continue }
                let delay: TimeInterval = self.hasPendingChanges ? 8 : 60
                if Date.now.timeIntervalSince(self.lastAttempt) >= delay { await self.syncNow() }
            }
        }
    }

    private func valid(_ operation: UUID, _ userID: UUID) -> Bool {
        operation == generation && currentUserID == userID && account?.userID == userID && !Task.isCancelled
    }

    private func record(_ values: [String: String], in state: inout Envelope) {
        let changes = CloudLibraryMerge.changes(from: state.lastProjection, to: values)
        state.pending.merge(changes) { _, latest in latest }
        state.values = CloudLibraryMerge.applying(changes: changes, to: state.values)
        state.lastProjection = values
    }

    private func refreshStatus() {
        hasPendingChanges = !envelope.pending.isEmpty
        lastSyncedAt = envelope.lastSyncedAt
    }

    private func showStorageError() {
        statusMessage = copy("Your latest changes could not be backed up on this iPhone. Free some storage and try again before signing out.", "تعذّر حفظ نسخة من أحدث تغييراتك على هذا الهاتف. وفّر مساحة تخزين ثم حاول مجددًا قبل تسجيل الخروج.")
    }

    private func persist() throws {
        guard let userID = currentUserID else { throw SyncError.unavailable }
        try write(envelope, to: fileURL(userID))
    }
    private var legacyURL: URL { directory.appendingPathComponent("pre-account-library.json") }
    private func fileURL(_ userID: UUID) -> URL { directory.appendingPathComponent("\(userID.uuidString).json") }
    private func readEnvelope(_ userID: UUID) throws -> Envelope? { try read(Envelope.self, at: fileURL(userID)) }
    private func read<T: Decodable>(_ type: T.Type, at url: URL) throws -> T? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }
    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(value).write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    enum SyncError: Error { case unavailable, contended }
}
