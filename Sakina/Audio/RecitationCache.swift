import Foundation

/// Downloaded ayah audio, kept under `Caches/recitation/<folder>/<SSSAAA>.mp3`
/// so the system may reclaim it under storage pressure. The cache coalesces
/// duplicate downloads, keeps at most three background prefetches in flight,
/// and evicts the least recently played files once it passes 300 MB.
actor RecitationCache {
    static let shared = RecitationCache()

    /// Upper bound before eviction runs.
    static let capacity: Int64 = 300 * 1024 * 1024
    /// Eviction trims down to this so it does not run after every download.
    private static let trimTarget: Int64 = 260 * 1024 * 1024
    private static let maxPrefetches = 3

    enum CacheError: Error {
        case badURL
        case badResponse(Int)
    }

    private let root: URL
    private let session: URLSession
    private var inFlight: [String: Task<URL, Error>] = [:]
    private var prefetchQueue: [(ayah: QuranAyah, reciter: Reciter)] = []
    private var activePrefetches = 0
    /// Total bytes on disk, computed lazily and kept in step with downloads.
    private var totalBytes: Int64?

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        root = caches.appendingPathComponent("recitation", isDirectory: true)

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        configuration.httpMaximumConnectionsPerHost = 4
        session = URLSession(configuration: configuration)
    }

    // MARK: Locations

    /// The CDN file for an ayah in the given recitation.
    nonisolated static func remoteURL(for ayah: QuranAyah, reciter: Reciter) -> URL? {
        URL(string: "https://everyayah.com/data/\(reciter.rawValue)/\(ayah.audioFile).mp3")
    }

    nonisolated func fileURL(for ayah: QuranAyah, reciter: Reciter) -> URL {
        root.appendingPathComponent(reciter.rawValue, isDirectory: true)
            .appendingPathComponent("\(ayah.audioFile).mp3", isDirectory: false)
    }

    private func key(_ ayah: QuranAyah, _ reciter: Reciter) -> String {
        "\(reciter.rawValue)/\(ayah.audioFile)"
    }

    /// The cached file if it is already on disk. Playing it counts as a use
    /// for eviction purposes.
    func localURL(for ayah: QuranAyah, reciter: Reciter) -> URL? {
        let url = fileURL(for: ayah, reciter: reciter)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
        return url
    }

    // MARK: Fetching

    /// Returns the local file, downloading it first when needed. Concurrent
    /// requests for the same ayah share one download.
    func fetch(ayah: QuranAyah, reciter: Reciter) async throws -> URL {
        if let local = localURL(for: ayah, reciter: reciter) { return local }
        let key = key(ayah, reciter)
        if let existing = inFlight[key] {
            return try await existing.value
        }
        let task = Task { try await download(ayah: ayah, reciter: reciter) }
        inFlight[key] = task
        defer { if inFlight[key] == task { inFlight[key] = nil } }
        return try await task.value
    }

    private func download(ayah: QuranAyah, reciter: Reciter) async throws -> URL {
        guard let remote = Self.remoteURL(for: ayah, reciter: reciter) else { throw CacheError.badURL }
        let (temporary, response) = try await session.download(from: remote)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            try? FileManager.default.removeItem(at: temporary)
            throw CacheError.badResponse((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        let destination = fileURL(for: ayah, reciter: reciter)
        let manager = FileManager.default
        try manager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)

        if manager.fileExists(atPath: destination.path) {
            // Another path wrote it meanwhile; keep the existing file.
            try? manager.removeItem(at: temporary)
            return destination
        }
        do {
            // A rename inside one volume is atomic, so a reader never sees a
            // half written file.
            try manager.moveItem(at: temporary, to: destination)
        } catch {
            try? manager.removeItem(at: temporary)
            guard manager.fileExists(atPath: destination.path) else { throw error }
        }

        var excluded = destination
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? excluded.setResourceValues(values)

        if let bytes = fileSize(destination) {
            totalBytes = (totalBytes ?? measure()) + bytes
        }
        trimIfNeeded()
        return destination
    }

    // MARK: Prefetching

    /// Queues ayat to download quietly in the background, at most three at a
    /// time so the audible download always has bandwidth.
    func prefetch(_ ayat: [QuranAyah], reciter: Reciter) {
        for ayah in ayat {
            let key = key(ayah, reciter)
            guard inFlight[key] == nil,
                  !prefetchQueue.contains(where: { $0.reciter == reciter && $0.ayah.key == ayah.key }),
                  !FileManager.default.fileExists(atPath: fileURL(for: ayah, reciter: reciter).path)
            else { continue }
            prefetchQueue.append((ayah, reciter))
        }
        pumpPrefetches()
    }

    /// Drops queued prefetches, e.g. when the reciter changes. Downloads
    /// already in flight finish and stay cached.
    func cancelPrefetch() {
        prefetchQueue.removeAll()
    }

    private func pumpPrefetches() {
        while activePrefetches < Self.maxPrefetches, !prefetchQueue.isEmpty {
            let next = prefetchQueue.removeFirst()
            activePrefetches += 1
            Task {
                _ = try? await fetch(ayah: next.ayah, reciter: next.reciter)
                activePrefetches -= 1
                pumpPrefetches()
            }
        }
    }

    // MARK: Size and eviction

    /// Bytes currently on disk.
    func size() -> Int64 {
        if let totalBytes { return totalBytes }
        let measured = measure()
        totalBytes = measured
        return measured
    }

    /// Removes every downloaded file.
    func clear() {
        prefetchQueue.removeAll()
        try? FileManager.default.removeItem(at: root)
        totalBytes = 0
    }

    private func measure() -> Int64 {
        files().reduce(0) { $0 + $1.bytes }
    }

    private func trimIfNeeded() {
        guard let totalBytes, totalBytes > Self.capacity else { return }
        var remaining = totalBytes
        let oldestFirst = files().sorted { $0.modified < $1.modified }
        for file in oldestFirst where remaining > Self.trimTarget {
            if (try? FileManager.default.removeItem(at: file.url)) != nil {
                remaining -= file.bytes
            }
        }
        self.totalBytes = remaining
    }

    private struct CachedFile {
        let url: URL
        let bytes: Int64
        let modified: Date
    }

    private func files() -> [CachedFile] {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
        ) else { return [] }
        var result: [CachedFile] = []
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else { continue }
            result.append(CachedFile(
                url: url,
                bytes: Int64(values.fileSize ?? 0),
                modified: values.contentModificationDate ?? .distantPast
            ))
        }
        return result
    }

    private func fileSize(_ url: URL) -> Int64? {
        (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init)
    }
}
