import AVFoundation
import Combine
import Foundation
import MediaPlayer

/// Converts the player's source timeline to the selected recording or excerpt.
/// Rejecting invalid ranges prevents a bad timestamp from playing another dua.
struct AdhkarPlaybackRange: Equatable {
    let start: TimeInterval
    let end: TimeInterval
    var duration: TimeInterval { end - start }

    init?(sourceDuration: TimeInterval, start: TimeInterval = 0, end: TimeInterval? = nil) {
        guard sourceDuration.isFinite, sourceDuration > 0, start.isFinite,
              end?.isFinite != false else { return nil }
        let boundedStart = max(0, start)
        let boundedEnd = min(sourceDuration, end ?? sourceDuration)
        guard boundedStart < boundedEnd else { return nil }
        self.start = boundedStart
        self.end = boundedEnd
    }

    func sourceTime(for relativeTime: TimeInterval) -> TimeInterval {
        guard relativeTime.isFinite else { return start }
        return start + min(max(relativeTime, 0), duration)
    }

    func relativeTime(for sourceTime: TimeInterval) -> TimeInterval {
        guard sourceTime.isFinite else { return 0 }
        return min(max(sourceTime - start, 0), duration)
    }
}

/// Offline playback of the reciter-authorized morning and evening recordings.
/// Times exposed to the UI and lock screen are relative to the chosen excerpt.
@MainActor
final class AdhkarAudioPlayer: ObservableObject {
    static let shared = AdhkarAudioPlayer()

    @Published private(set) var recording: AdhkarRecording?
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var startTime: TimeInterval = 0
    @Published private(set) var endTime: TimeInterval?
    @Published private(set) var errorMessage: String?
    var isFullRecording: Bool { startTime == 0 && endTime == nil }

    func playbackTitle(_ language: AppLanguage) -> String {
        guard let recording else { return "" }
        if !isFullRecording,
           let chapter = recording.chapters.first(where: { $0.start == startTime && $0.end == endTime }) {
            return chapter.title(language)
        }
        return recording.title(language)
    }

    private let player = AVPlayer()
    private var playbackRange: AdhkarPlaybackRange?
    private var loadingTask: Task<Void, Never>?
    private var generation = 0
    private var seekGeneration = 0
    private var isSeeking = false
    private var itemStatusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var notificationTokens: [NSObjectProtocol] = []
    private var remoteCommandTargets: [(MPRemoteCommand, Any)] = []
    private var ownsNowPlaying = false
    private var wasPlayingBeforeInterruption = false

    private init() {
        player.actionAtItemEnd = .pause
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                // Read the current item, not a tick queued before a recording switch.
                self.updateTime(self.player.currentTime().seconds)
            }
        }
        timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.recording != nil else { return }
                self.isBuffering = self.isPlaying &&
                    (self.loadingTask != nil || self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate)
                self.updateNowPlaying()
            }
        }
        observeAudioSession()
        notificationTokens.append(NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: .main
        ) { [weak self] note in
            let finishedItem = note.object as? AVPlayerItem
            Task { @MainActor [weak self] in
                guard let self, let finishedItem,
                      finishedItem === self.player.currentItem,
                      !self.isSeeking,
                      let range = self.playbackRange,
                      self.player.currentTime().seconds >= range.end - 0.05 else { return }
                self.finishPlayback()
            }
        })
    }

    /// Optional verified timestamps play a bounded excerpt without duplicating the audio file.
    func play(recording: AdhkarRecording, startTime: TimeInterval = 0, endTime: TimeInterval? = nil) {
        stop()
        guard let url = Bundle.main.url(forResource: "adhkar-\(recording.rawValue)", withExtension: "mp3") else {
            showPlaybackError()
            return
        }
        MushafPlayer.shared.stop()
        RecitationPlayer.shared.stop()
        self.recording = recording
        self.startTime = startTime
        self.endTime = endTime
        guard activateAudioSession() else { return }
        installRemoteCommands()
        isPlaying = true
        isBuffering = true
        updateNowPlaying()

        let generation = generation
        loadingTask = Task { [weak self] in
            do {
                let asset = AVURLAsset(url: url)
                let sourceDuration = try await asset.load(.duration).seconds
                guard let self, !Task.isCancelled, self.generation == generation else { return }
                guard let range = AdhkarPlaybackRange(sourceDuration: sourceDuration,
                                                      start: startTime, end: endTime) else {
                    self.showPlaybackError()
                    return
                }
                self.playbackRange = range
                self.duration = range.duration
                let item = AVPlayerItem(asset: asset)
                // AVPlayer enforces the exact end even while the app is in the background.
                item.forwardPlaybackEndTime = CMTime(seconds: range.end, preferredTimescale: 600)
                self.player.replaceCurrentItem(with: item)
                self.itemStatusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                    Task { @MainActor [weak self] in
                        guard let self, item === self.player.currentItem,
                              self.generation == generation else { return }
                        if item.status == .failed { self.showPlaybackError() }
                    }
                }
                self.loadingTask = nil
                self.seek(to: 0)
            } catch {
                guard let self, !Task.isCancelled, self.generation == generation else { return }
                self.showPlaybackError()
            }
        }
    }

    func toggle() {
        if isPlaying { pause() } else { resume() }
    }

    func pause() {
        wasPlayingBeforeInterruption = false
        guard recording != nil else { return }
        player.pause()
        isPlaying = false
        isBuffering = false
        updateNowPlaying()
    }

    private func resume() {
        guard recording != nil else { return }
        MushafPlayer.shared.stop()
        RecitationPlayer.shared.stop()
        guard activateAudioSession() else { return }
        installRemoteCommands()
        isPlaying = true
        if duration > 0, currentTime >= duration - 0.05 {
            seek(to: 0)
        } else if player.currentItem != nil {
            player.play()
        } else {
            isBuffering = loadingTask != nil
        }
        updateNowPlaying()
    }

    /// Seek within the selected recording/excerpt, in seconds from its beginning.
    func seek(to time: TimeInterval) {
        guard let playbackRange, player.currentItem != nil, time.isFinite else { return }
        let sourceTime = playbackRange.sourceTime(for: time)
        currentTime = playbackRange.relativeTime(for: sourceTime)
        if currentTime >= duration { pause() }
        seekGeneration += 1
        isSeeking = true
        let seekGeneration = seekGeneration
        let generation = generation
        player.seek(to: CMTime(seconds: sourceTime, preferredTimescale: 600),
                    toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completed in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation,
                      self.seekGeneration == seekGeneration else { return }
                self.isSeeking = false
                guard completed else {
                    self.pause()
                    return
                }
                if self.isPlaying { self.player.play() }
                self.isBuffering = self.isPlaying && self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                self.updateNowPlaying()
            }
        }
        updateNowPlaying()
    }

    func skip(seconds: TimeInterval) {
        guard seconds.isFinite else { return }
        seek(to: currentTime + seconds)
    }

    func clearError() {
        errorMessage = nil
    }

    func stop() {
        generation += 1
        seekGeneration += 1
        isSeeking = false
        loadingTask?.cancel()
        loadingTask = nil
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        playbackRange = nil
        recording = nil
        isPlaying = false
        isBuffering = false
        currentTime = 0
        duration = 0
        startTime = 0
        endTime = nil
        errorMessage = nil
        wasPlayingBeforeInterruption = false
        removeRemoteCommands()
        if ownsNowPlaying {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            ownsNowPlaying = false
        }
    }

    /// Accepts AVPlayer ticks. A tick from before an unfinished seek must not
    /// overwrite its requested position or finish a replay at the previous end.
    func updateTime(_ sourceTime: TimeInterval) {
        guard !isSeeking, let playbackRange, sourceTime.isFinite else { return }
        currentTime = playbackRange.relativeTime(for: sourceTime)
        if currentTime >= duration, isPlaying { finishPlayback() }
    }

    private func finishPlayback() {
        pause()
        currentTime = duration
        updateNowPlaying()
    }

    private func showPlaybackError() {
        stop()
        let language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: SettingsKeys.appLanguage) ?? "") ?? .english
        errorMessage = language.pick("This recording couldn’t play. Please try again.",
                                     "تعذّر تشغيل التسجيل. يرجى المحاولة مجددًا.")
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

    private func observeAudioSession() {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()
        notificationTokens.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification, object: session, queue: .main
        ) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            let options = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch type {
                case .began:
                    let shouldResume = self.isPlaying
                    self.pause()
                    self.wasPlayingBeforeInterruption = shouldResume
                case .ended:
                    let shouldResume = self.wasPlayingBeforeInterruption &&
                        AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume)
                    self.wasPlayingBeforeInterruption = false
                    if shouldResume { self.resume() }
                @unknown default: break
                }
            }
        })
        notificationTokens.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: session, queue: .main
        ) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
            Task { @MainActor [weak self] in self?.pause() }
        })
    }

    private func updateNowPlaying() {
        guard ownsNowPlaying, recording != nil else { return }
        let language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: SettingsKeys.appLanguage) ?? "") ?? .english
        HaneenNowPlaying.publish([
            MPMediaItemPropertyTitle: playbackTitle(language),
            MPMediaItemPropertyArtist: language.pick("Abu Islam", "أبو إسلام"),
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying && !isBuffering ? 1.0 : 0.0
        ])
    }

    private func installRemoteCommands() {
        guard remoteCommandTargets.isEmpty else { return }
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.changePlaybackPositionCommand.isEnabled = true
        center.skipForwardCommand.isEnabled = true
        center.skipBackwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.preferredIntervals = [15]
        center.seekForwardCommand.isEnabled = false
        center.seekBackwardCommand.isEnabled = false

        addRemoteTarget(center.playCommand) { $0.resume() }
        addRemoteTarget(center.pauseCommand) { $0.pause() }
        addRemoteTarget(center.togglePlayPauseCommand) { $0.toggle() }
        addRemoteTarget(center.skipForwardCommand) { $0.skip(seconds: 15) }
        addRemoteTarget(center.skipBackwardCommand) { $0.skip(seconds: -15) }
        let target = center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let position = event.positionTime
            Task { @MainActor [weak self] in
                guard let self, self.ownsNowPlaying else { return }
                self.seek(to: position)
            }
            return .success
        }
        remoteCommandTargets.append((center.changePlaybackPositionCommand, target))
    }

    private func addRemoteTarget(_ command: MPRemoteCommand,
                                 action: @escaping @MainActor (AdhkarAudioPlayer) -> Void) {
        let target = command.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.ownsNowPlaying else { return }
                action(self)
            }
            return .success
        }
        remoteCommandTargets.append((command, target))
    }

    private func removeRemoteCommands() {
        for (command, target) in remoteCommandTargets { command.removeTarget(target) }
        remoteCommandTargets.removeAll()
    }
}
