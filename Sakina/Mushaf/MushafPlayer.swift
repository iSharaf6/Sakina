import AVFoundation
import Combine
import Foundation
import MediaPlayer

/// Plays recitation ayah by ayah from the everyayah CDN, continuing through
/// the mushaf until stopped. The reader watches `playingKey` to follow along.
///
/// Playback runs on one `AVQueuePlayer`. The current ayah is served from
/// `RecitationCache` when it is on disk and streamed otherwise; the following
/// ayah is downloaded and enqueued while the current one plays so the join is
/// gapless, and the two after that are prefetched in the background.
@MainActor
final class MushafPlayer: ObservableObject {
    static let shared = MushafPlayer()

    @Published private(set) var playingKey: String?
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false
    /// 0...1 through the current ayah.
    @Published private(set) var progress: Double = 0
    @Published private(set) var reciter: Reciter

    /// Stop at the end of this surah when set; otherwise keep going.
    var stopAtSurahEnd = true {
        didSet { if oldValue != stopAtSurahEnd { rebuildUpcoming() } }
    }
    /// Loop the current ayah instead of advancing.
    var repeatCurrent = false {
        didSet { if oldValue != repeatCurrent { rebuildUpcoming() } }
    }

    private struct Entry {
        let key: String
        let url: URL
    }

    private let queue = AVQueuePlayer()
    private let cache = RecitationCache.shared
    private var entries: [AVPlayerItem: Entry] = [:]
    /// Bumped on every restart so stale async work can bail out.
    private var generation = 0
    private var suppressQueueEvents = false
    private var consecutiveFailures = 0
    private var wasPlayingBeforeInterruption = false

    private var startTask: Task<Void, Never>?
    private var upcomingTask: Task<Void, Never>?
    private var currentItemObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    private var itemStatusObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var notificationTokens: [NSObjectProtocol] = []

    private init() {
        let stored = UserDefaults.standard.string(forKey: SettingsKeys.reciter) ?? ""
        reciter = Reciter(rawValue: stored) ?? .alafasy
        queue.actionAtItemEnd = .advance
        observeQueue()
        observeSession()
        installRemoteCommands()
    }

    // MARK: Public API

    func url(for ayah: QuranAyah) -> URL? {
        RecitationCache.remoteURL(for: ayah, reciter: reciter)
    }

    /// Start at `key` and continue with the following ayat.
    func play(from key: String) {
        guard let ayah = QuranStore.shared.ayah(key) else { return }
        RecitationPlayer.shared.stop()
        activateSession()
        resetQueue()

        playingKey = key
        isPlaying = true
        isBuffering = true
        progress = 0
        updateNowPlaying()

        let generation = generation
        let reciter = reciter
        startTask = Task { [weak self] in
            guard let self else { return }
            let url: URL
            if let local = await self.cache.localURL(for: ayah, reciter: reciter) {
                url = local
            } else {
                guard let remote = RecitationCache.remoteURL(for: ayah, reciter: reciter) else { return }
                url = remote
                // Stream now, keep a copy for next time.
                await self.cache.prefetch([ayah], reciter: reciter)
            }
            guard !Task.isCancelled, self.generation == generation else { return }
            self.enqueue(url, for: ayah.key)
            self.queue.play()
        }
    }

    func toggle(_ key: String) {
        if playingKey == key {
            if isPlaying { pause() } else { resume() }
        } else {
            play(from: key)
        }
    }

    func pause() {
        guard playingKey != nil else { return }
        queue.pause()
        isPlaying = false
        updateNowPlaying()
    }

    func resume() {
        guard let key = playingKey else { return }
        activateSession()
        if queue.currentItem == nil {
            play(from: key)
            return
        }
        queue.play()
        isPlaying = true
        updateNowPlaying()
    }

    func stop() {
        resetQueue()
        playingKey = nil
        isPlaying = false
        isBuffering = false
        progress = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func playNext() {
        guard let key = playingKey, let next = QuranStore.shared.next(after: key) else { return }
        play(from: next.key)
    }

    func playPrevious() {
        guard let key = playingKey else { return }
        if let previous = QuranStore.shared.previous(before: key) {
            play(from: previous.key)
        } else {
            queue.seek(to: .zero)
        }
    }

    /// Persists the choice and restarts the current ayah in the new voice.
    func setReciter(_ newValue: Reciter) {
        guard newValue != reciter else { return }
        reciter = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: SettingsKeys.reciter)
        Task { await cache.cancelPrefetch() }
        if let key = playingKey { play(from: key) }
    }

    // MARK: Queue management

    private func enqueue(_ url: URL, for key: String) {
        let item = AVPlayerItem(url: url)
        entries[item] = Entry(key: key, url: url)
        queue.insert(item, after: nil)
    }

    private func resetQueue() {
        generation += 1
        startTask?.cancel()
        startTask = nil
        upcomingTask?.cancel()
        upcomingTask = nil
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil
        suppressQueueEvents = true
        queue.pause()
        queue.removeAllItems()
        suppressQueueEvents = false
        entries.removeAll()
        consecutiveFailures = 0
    }

    private func nextKey(after key: String) -> String? {
        if repeatCurrent { return key }
        guard let next = QuranStore.shared.next(after: key) else { return nil }
        if stopAtSurahEnd, let current = QuranStore.shared.ayah(key), next.surah != current.surah { return nil }
        return next.key
    }

    /// Drops whatever is queued after the current ayah and requeues it under
    /// the current repeat and surah-end rules.
    private func rebuildUpcoming() {
        guard let current = queue.currentItem, let key = entries[current]?.key else { return }
        upcomingTask?.cancel()
        for item in queue.items() where item !== current {
            queue.remove(item)
            entries[item] = nil
        }
        prepareUpcoming(after: key, current: current)
    }

    /// Downloads the next ayah while this one plays and appends it to the
    /// queue, then prefetches the two after it.
    private func prepareUpcoming(after key: String, current: AVPlayerItem) {
        upcomingTask?.cancel()
        guard let nextKey = nextKey(after: key), let next = QuranStore.shared.ayah(nextKey) else { return }
        let generation = generation
        let reciter = reciter
        let cache = cache
        upcomingTask = Task { [weak self] in
            var resolved = await cache.localURL(for: next, reciter: reciter)
            if resolved == nil {
                resolved = try? await cache.fetch(ayah: next, reciter: reciter)
            }
            guard let self, !Task.isCancelled, self.generation == generation else { return }
            // If the download failed, fall back to streaming so playback still continues.
            guard let url = resolved ?? RecitationCache.remoteURL(for: next, reciter: reciter),
                  self.queue.currentItem === current, self.queue.items().count == 1 else { return }
            self.enqueue(url, for: next.key)

            var ahead: [QuranAyah] = []
            var cursor = next.key
            for _ in 0..<2 {
                guard let following = QuranStore.shared.next(after: cursor) else { break }
                ahead.append(following)
                cursor = following.key
            }
            if !ahead.isEmpty { await cache.prefetch(ahead, reciter: reciter) }
        }
    }

    // MARK: Queue events

    private func observeQueue() {
        currentItemObserver = queue.observe(\.currentItem, options: [.new]) { [weak self] _, change in
            let item = change.newValue ?? nil
            Task { @MainActor [weak self] in self?.currentItemChanged(to: item) }
        }
        timeControlObserver = queue.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let waiting = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            Task { @MainActor [weak self] in
                guard let self, self.playingKey != nil else { return }
                self.isBuffering = waiting
            }
        }
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = queue.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated { self?.updateProgress(at: time) }
        }
    }

    private func currentItemChanged(to item: AVPlayerItem?) {
        guard !suppressQueueEvents else { return }
        if let item {
            itemStarted(item)
        } else if playingKey != nil {
            // The queue ran dry before the next ayah was ready: carry on by
            // streaming it, or finish.
            advanceAfterQueueEmptied()
        }
    }

    private func itemStarted(_ item: AVPlayerItem) {
        guard let entry = entries[item] else { return }
        // Forget items the queue has already released.
        let live = queue.items()
        entries = entries.filter { live.contains($0.key) }

        playingKey = entry.key
        progress = 0
        isBuffering = item.status != .readyToPlay
        observeStatus(of: item)
        updateNowPlaying()
        prepareUpcoming(after: entry.key, current: item)
    }

    private func observeStatus(of item: AVPlayerItem) {
        itemStatusObserver?.invalidate()
        itemStatusObserver = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            let status = item.status
            Task { @MainActor [weak self] in self?.statusChanged(status, for: item) }
        }
    }

    private func statusChanged(_ status: AVPlayerItem.Status, for item: AVPlayerItem) {
        guard item === queue.currentItem else { return }
        switch status {
        case .readyToPlay:
            consecutiveFailures = 0
            isBuffering = queue.timeControlStatus == .waitingToPlayAtSpecifiedRate
            updateNowPlaying()
        case .failed:
            consecutiveFailures += 1
            if let entry = entries[item], entry.url.isFileURL {
                // A damaged download; drop it so the next attempt refetches.
                try? FileManager.default.removeItem(at: entry.url)
            }
            if consecutiveFailures >= 3 {
                stop()
            } else {
                queue.advanceToNextItem()
            }
        default:
            break
        }
    }

    private func advanceAfterQueueEmptied() {
        guard let key = playingKey else { return }
        if let next = nextKey(after: key) {
            play(from: next)
        } else {
            stop()
        }
    }

    private func updateProgress(at time: CMTime) {
        guard let item = queue.currentItem else { return }
        let duration = item.duration
        guard duration.isNumeric, duration.seconds > 0 else { return }
        let fraction = time.seconds / duration.seconds
        progress = min(max(fraction, 0), 1)
    }

    // MARK: Audio session

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }

    private func observeSession() {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()
        notificationTokens.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification, object: session, queue: .main
        ) { [weak self] note in
            guard let info = note.userInfo,
                  let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            let optionsRaw = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let shouldResume = AVAudioSession.InterruptionOptions(rawValue: optionsRaw).contains(.shouldResume)
            Task { @MainActor [weak self] in self?.handleInterruption(type, shouldResume: shouldResume) }
        })
        notificationTokens.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: session, queue: .main
        ) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
            // Headphones unplugged: do not blast the room.
            Task { @MainActor [weak self] in self?.pause() }
        })
        notificationTokens.append(center.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.syncReciterFromDefaults() }
        })
    }

    private func handleInterruption(_ type: AVAudioSession.InterruptionType, shouldResume: Bool) {
        switch type {
        case .began:
            wasPlayingBeforeInterruption = isPlaying
            if isPlaying { pause() }
        case .ended:
            if wasPlayingBeforeInterruption, shouldResume { resume() }
            wasPlayingBeforeInterruption = false
        @unknown default:
            break
        }
    }

    /// Settings changes the reciter through `@AppStorage`; follow it.
    private func syncReciterFromDefaults() {
        let stored = UserDefaults.standard.string(forKey: SettingsKeys.reciter) ?? ""
        guard let chosen = Reciter(rawValue: stored), chosen != reciter else { return }
        setReciter(chosen)
    }

    // MARK: Now playing and remote commands

    private func updateNowPlaying() {
        guard let key = playingKey, let ayah = QuranStore.shared.ayah(key) else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        let language = AppLanguage(
            rawValue: UserDefaults.standard.string(forKey: SettingsKeys.appLanguage) ?? ""
        ) ?? .english
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: ayah.reference(language),
            MPMediaItemPropertyArtist: reciter.name(language),
            MPMediaItemPropertyAlbumTitle: "Yaqeen",
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let item = queue.currentItem {
            if item.duration.isNumeric { info[MPMediaItemPropertyPlaybackDuration] = item.duration.seconds }
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = item.currentTime().seconds
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func installRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.resume() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.isPlaying { self.pause() } else { self.resume() }
            }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.playNext() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.playPrevious() }
            return .success
        }
        center.changePlaybackPositionCommand.isEnabled = false
        center.seekForwardCommand.isEnabled = false
        center.seekBackwardCommand.isEnabled = false
    }
}
