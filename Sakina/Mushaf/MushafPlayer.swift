import AVFoundation
import Combine
import Foundation

/// Plays recitation ayah by ayah from the everyayah CDN, continuing through
/// the mushaf until stopped. The reader watches `playingKey` to follow along.
@MainActor
final class MushafPlayer: ObservableObject {
    static let shared = MushafPlayer()

    @Published private(set) var playingKey: String?
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false
    /// Stop at the end of this surah when set; otherwise keep going.
    var stopAtSurahEnd = true

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?

    private init() {}

    private var reciterFolder: String {
        UserDefaults.standard.string(forKey: SettingsKeys.reciter) ?? Reciter.alafasy.rawValue
    }

    func url(for ayah: QuranAyah) -> URL? {
        URL(string: "https://everyayah.com/data/\(reciterFolder)/\(ayah.audioFile).mp3")
    }

    /// Start at `key` and continue with the following ayat.
    func play(from key: String) {
        guard let ayah = QuranStore.shared.ayah(key), let url = url(for: ayah) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        tearDown()
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        playingKey = key
        isPlaying = true
        isBuffering = true
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                switch item.status {
                case .readyToPlay: self.isBuffering = false
                case .failed: self.advance()
                default: break
                }
            }
        }
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.advance() }
        }
        player.play()
    }

    func toggle(_ key: String) {
        if playingKey == key {
            if isPlaying { pause() } else { resume() }
        } else {
            play(from: key)
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func stop() {
        tearDown()
        playingKey = nil
        isPlaying = false
        isBuffering = false
    }

    private func advance() {
        guard let current = playingKey, let next = QuranStore.shared.next(after: current) else { stop(); return }
        if stopAtSurahEnd, let ayah = QuranStore.shared.ayah(current), next.surah != ayah.surah { stop(); return }
        play(from: next.key)
    }

    private func tearDown() {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        statusObserver?.invalidate()
        statusObserver = nil
        player?.pause()
        player = nil
    }
}
