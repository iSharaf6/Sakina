import Foundation
import AVFoundation

/// Streams verse by verse recitation for a situation using the reciter chosen
/// in settings, queueing multi ayah passages so ranges play continuously.
@MainActor
final class RecitationPlayer: ObservableObject {
    static let shared = RecitationPlayer()

    @Published private(set) var playingID: String?

    private var player: AVQueuePlayer?
    private var lastItem: AVPlayerItem?
    private var endObserver: NSObjectProtocol?

    private init() {}

    func toggle(situation: Situation) {
        if playingID == situation.id {
            stop()
        } else {
            play(situation: situation)
        }
    }

    func play(situation: Situation) {
        stop()

        let folder = UserDefaults.standard.string(forKey: SettingsKeys.reciter)
            ?? Reciter.alafasy.rawValue
        let items = situation.verses.compactMap { verse in
            URL(string: "https://everyayah.com/data/\(folder)/\(verse.audioFile).mp3")
                .map { AVPlayerItem(url: $0) }
        }
        guard !items.isEmpty else { return }

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        let queue = AVQueuePlayer(items: items)
        player = queue
        lastItem = items.last

        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            Task { @MainActor [weak self] in
                guard let self,
                      let item = note.object as? AVPlayerItem,
                      item === self.lastItem else { return }
                self.stop()
            }
        }

        queue.play()
        playingID = situation.id
    }

    func stop() {
        player?.pause()
        player?.removeAllItems()
        player = nil
        lastItem = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        playingID = nil
    }

    func stopIfPlaying(id: String) {
        if playingID == id { stop() }
    }
}
