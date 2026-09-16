import AVFoundation
import Combine
import Foundation
import MediaPlayer

/// A situation's selected ayat continue playing when its reader is dismissed.
/// The app-wide player and system media controls own the listening session.
@MainActor
final class RecitationPlayer: ObservableObject {
    static let shared = RecitationPlayer()

    @Published private(set) var playingID: String?
    @Published private(set) var situation: Situation?
    @Published private(set) var currentVerse: Verse?
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var reciter = Reciter.alafasy
    @Published private(set) var errorMessage: String?

    private let player = AVQueuePlayer()
    private var sourceURLs: [URL] = []
    private var failedSituation: Situation?
    private var verses: [Verse] = []
    private var indices: [AVPlayerItem: Int] = [:]
    private var currentIndex = 0
    private var itemObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var notificationTokens: [NSObjectProtocol] = []
    private var remoteCommandTargets: [(MPRemoteCommand, Any)] = []
    private var ownsNowPlaying = false
    private var wasPlayingBeforeInterruption = false

    private init() {
        player.actionAtItemEnd = .advance
        itemObserver = player.observe(\.currentItem, options: [.new]) { [weak self] _, change in
            let item = change.newValue ?? nil
            Task { @MainActor [weak self] in
                guard let self, self.playingID != nil,
                      item === self.player.currentItem else { return }
                guard let item, let index = self.indices[item] else {
                    if self.indices.keys.contains(where: { $0.status == .failed }) {
                        self.showPlaybackError()
                    } else {
                        self.stop()
                    }
                    return
                }
                self.currentIndex = index
                self.currentVerse = self.verses[index]
                self.currentTime = 0
                self.duration = 0
                self.observeStatus(item)
                self.updateNowPlaying()
            }
        }
        timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.playingID != nil else { return }
                self.isBuffering = self.isPlaying && self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                self.updateNowPlaying()
            }
        }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.playingID != nil else { return }
                let time = self.player.currentTime().seconds
                if time.isFinite { self.currentTime = max(0, time) }
                self.updateDuration()
            }
        }
        observeAudioSession()
    }

    func toggle(situation: Situation) {
        if playingID == situation.id {
            if isPlaying { pause() } else { resume() }
        } else {
            play(situation: situation)
        }
    }

    /// `sourceURLs` also allows integration tests to use shipped audio offline.
    func play(situation: Situation, sourceURLs: [URL]? = nil) {
        stop()
        let chosen = Reciter(rawValue: UserDefaults.standard.string(forKey: SettingsKeys.reciter) ?? "") ?? .alafasy
        let verses = situation.verses
        let urls = sourceURLs ?? verses.compactMap {
            URL(string: "https://everyayah.com/data/\(chosen.rawValue)/\($0.audioFile).mp3")
        }
        guard !verses.isEmpty, urls.count == verses.count else { return }
        MushafPlayer.shared.stop()
        AdhkarAudioPlayer.shared.stop()
        self.situation = situation
        self.playingID = situation.id
        self.reciter = chosen
        self.verses = verses
        self.sourceURLs = urls
        guard activateAudioSession() else { return }
        installRemoteCommands()
        startQueue(at: 0)
    }

    func pause() {
        wasPlayingBeforeInterruption = false
        guard playingID != nil else { return }
        player.pause()
        isPlaying = false
        isBuffering = false
        updateNowPlaying()
    }

    func resume() {
        guard playingID != nil else { return }
        MushafPlayer.shared.stop()
        AdhkarAudioPlayer.shared.stop()
        guard activateAudioSession() else { return }
        installRemoteCommands()
        isPlaying = true
        player.play()
        updateNowPlaying()
    }

    func clearError() { errorMessage = nil }

    func retryAfterFailure() {
        guard let situation = failedSituation else { return }
        play(situation: situation)
    }

    func playNext() {
        guard currentIndex + 1 < verses.count else { return }
        startQueue(at: currentIndex + 1)
    }

    func playPrevious() {
        guard playingID != nil else { return }
        startQueue(at: max(0, currentIndex - 1))
    }

    func seek(to time: TimeInterval) {
        guard time.isFinite, duration > 0, let item = player.currentItem else { return }
        let position = min(max(0, time), duration)
        currentTime = position
        player.seek(to: CMTime(seconds: position, preferredTimescale: 600)) { [weak self, weak item] _ in
            Task { @MainActor [weak self, weak item] in
                guard let self, let item, self.player.currentItem === item else { return }
                self.updateNowPlaying()
            }
        }
    }

    func stop() {
        statusObserver?.invalidate()
        statusObserver = nil
        player.pause()
        player.removeAllItems()
        indices.removeAll()
        sourceURLs.removeAll()
        verses.removeAll()
        playingID = nil
        situation = nil
        currentVerse = nil
        currentIndex = 0
        isPlaying = false
        isBuffering = false
        currentTime = 0
        duration = 0
        errorMessage = nil
        failedSituation = nil
        wasPlayingBeforeInterruption = false
        for (command, token) in remoteCommandTargets { command.removeTarget(token) }
        remoteCommandTargets.removeAll()
        if ownsNowPlaying {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            ownsNowPlaying = false
        }
    }

    private func startQueue(at index: Int) {
        guard verses.indices.contains(index) else { return }
        statusObserver?.invalidate()
        player.pause()
        player.removeAllItems()
        indices.removeAll()
        currentIndex = index
        currentVerse = verses[index]
        currentTime = 0
        duration = 0
        for position in index..<verses.count {
            let item = AVPlayerItem(url: sourceURLs[position])
            indices[item] = position
            player.insert(item, after: nil)
        }
        isPlaying = true
        isBuffering = true
        player.play()
        updateNowPlaying()
    }

    private func observeStatus(_ item: AVPlayerItem) {
        statusObserver?.invalidate()
        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self, self.player.currentItem === item else { return }
                if item.status == .failed {
                    self.showPlaybackError()
                } else if item.status == .readyToPlay {
                    self.updateDuration()
                    self.updateNowPlaying()
                }
            }
        }
    }

    private func updateDuration() {
        guard let value = player.currentItem?.duration.seconds, value.isFinite, value > 0 else { return }
        if duration != value { duration = value }
    }

    private func activateAudioSession() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
            ownsNowPlaying = true
            return true
        } catch {
            showPlaybackError()
            return false
        }
    }

    private func showPlaybackError() {
        let failed = situation
        stop()
        failedSituation = failed
        errorMessage = language.pick("This recitation couldn’t play. Check your connection and try again.",
                                     "تعذّر تشغيل التلاوة. تحقّق من اتصالك وحاول مجددًا.")
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: SettingsKeys.appLanguage) ?? "") ?? .english
    }

    private func observeAudioSession() {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()
        notificationTokens.append(center.addObserver(forName: AVAudioSession.interruptionNotification,
                                                     object: session, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            let options = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch type {
                case .began:
                    let playing = self.isPlaying
                    self.pause()
                    self.wasPlayingBeforeInterruption = playing
                case .ended:
                    let resume = self.wasPlayingBeforeInterruption &&
                        AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume)
                    self.wasPlayingBeforeInterruption = false
                    if resume { self.resume() }
                @unknown default: break
                }
            }
        })
        notificationTokens.append(center.addObserver(forName: AVAudioSession.routeChangeNotification,
                                                     object: session, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
            Task { @MainActor [weak self] in self?.pause() }
        })
    }

    private func updateNowPlaying() {
        guard ownsNowPlaying, let situation else { return }
        let title = currentVerse.map {
            language == .arabic ? "\($0.surahNameArabic) \($0.key)" : $0.reference
        } ?? situation.localizedTitle(language)
        HaneenNowPlaying.publish([
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: reciter.name(language),
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying && !isBuffering ? 1.0 : 0.0
        ])
    }

    private func installRemoteCommands() {
        guard remoteCommandTargets.isEmpty else { return }
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
        center.seekForwardCommand.isEnabled = false
        center.seekBackwardCommand.isEnabled = false
        addRemoteTarget(center.playCommand) { $0.resume() }
        addRemoteTarget(center.pauseCommand) { $0.pause() }
        addRemoteTarget(center.togglePlayPauseCommand) { player in
            if player.isPlaying { player.pause() } else { player.resume() }
        }
        addRemoteTarget(center.nextTrackCommand) { $0.playNext() }
        addRemoteTarget(center.previousTrackCommand) { $0.playPrevious() }
        let token = center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let position = event.positionTime
            Task { @MainActor [weak self] in
                guard let self, self.ownsNowPlaying else { return }
                self.seek(to: position)
            }
            return .success
        }
        remoteCommandTargets.append((center.changePlaybackPositionCommand, token))
    }

    private func addRemoteTarget(_ command: MPRemoteCommand,
                                 action: @escaping @MainActor (RecitationPlayer) -> Void) {
        let token = command.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.ownsNowPlaying else { return }
                action(self)
            }
            return .success
        }
        remoteCommandTargets.append((command, token))
    }
}
