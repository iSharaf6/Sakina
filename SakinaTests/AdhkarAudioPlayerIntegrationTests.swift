import AVFoundation
import MediaPlayer
import XCTest
@testable import Sakina

/// Exercises the shipped files and AVPlayer, without streaming or network fixtures.
@MainActor
final class AdhkarAudioPlayerIntegrationTests: XCTestCase {
    private var player: AdhkarAudioPlayer { .shared }

    override func setUp() async throws {
        try await super.setUp()
        player.stop()
        MushafPlayer.shared.stop()
        RecitationPlayer.shared.stop()
    }

    override func tearDown() async throws {
        player.stop()
        MushafPlayer.shared.stop()
        RecitationPlayer.shared.stop()
        try await super.tearDown()
    }

    func testBundledMorningRecordingIsPlayableAndComplete() async throws {
        try await assertBundledAsset(.morning, expectedDuration: 1291.937938)
    }

    func testBundledEveningRecordingIsPlayableAndComplete() async throws {
        try await assertBundledAsset(.evening, expectedDuration: 1332.793437)
    }

    func testRapidRecordingSwitchKeepsTheLastSelection() async throws {
        player.play(recording: .morning)
        // Switch before the morning asset's asynchronous duration load can finish.
        player.play(recording: .evening)
        try await waitUntil("Evening recording should finish loading") {
            self.player.duration > 0 && !self.player.isBuffering
        }
        try await waitUntil("The selected recording should actually advance") {
            self.player.currentTime > 0.05
        }
        XCTAssertEqual(player.recording, .evening)
        XCTAssertEqual(player.duration, 1332.793437, accuracy: 0.2)
        XCTAssertTrue(player.isFullRecording)
        XCTAssertTrue(player.isPlaying)
        XCTAssertNil(player.errorMessage)
    }

    func testPauseWhileLoadingDoesNotAutoplayWhenTheAssetArrives() async throws {
        player.play(recording: .morning)
        XCTAssertEqual(player.duration, 0, "Duration loading must not block the main actor")
        player.pause()
        try await waitUntil("Paused recording should still finish preparing") {
            self.player.duration > 0 && !self.player.isBuffering
        }
        // Let seek completion and several periodic ticks run after the load finishes.
        try await Task.sleep(nanoseconds: 350_000_000)
        XCTAssertEqual(player.recording, .morning)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.currentTime, 0, accuracy: 0.05)
        XCTAssertNil(player.errorMessage)
    }

    func testExcerptSeekingAndSkippingStayWithinItsBoundaries() async throws {
        player.play(recording: .morning, startTime: 300, endTime: 330)
        try await waitUntil("Excerpt should finish loading") {
            self.player.duration > 0 && !self.player.isBuffering
        }
        XCTAssertFalse(player.isFullRecording)
        XCTAssertEqual(player.startTime, 300)
        XCTAssertEqual(player.endTime, 330)
        XCTAssertEqual(player.duration, 30, accuracy: 0.01)

        player.seek(to: 10_000)
        try await waitUntil("Seeking past the excerpt should pause at its end") {
            !self.player.isPlaying && abs(self.player.currentTime - 30) < 0.05
        }
        try await Task.sleep(nanoseconds: 350_000_000)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.currentTime, 30, accuracy: 0.05)

        player.seek(to: -10_000)
        try await waitUntil("Seeking before the excerpt should stay at its beginning") {
            abs(self.player.currentTime) < 0.05
        }
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(player.currentTime, 0, accuracy: 0.05)
        XCTAssertFalse(player.isPlaying)

        player.skip(seconds: 10_000)
        XCTAssertEqual(player.currentTime, 30, accuracy: 0.05)
        XCTAssertFalse(player.isPlaying)
        XCTAssertNil(player.errorMessage)
    }

    func testExcerptStopsNaturallyAtItsAudioBoundary() async throws {
        player.play(recording: .evening, startTime: 300, endTime: 300.6)
        try await waitUntil("The short excerpt should reach its configured end") {
            self.player.duration > 0 && !self.player.isPlaying &&
                abs(self.player.currentTime - self.player.duration) < 0.05
        }
        XCTAssertEqual(player.duration, 0.6, accuracy: 0.01)
        XCTAssertEqual(player.currentTime, 0.6, accuracy: 0.05)
        XCTAssertFalse(player.isBuffering)
        XCTAssertNil(player.errorMessage)
    }

    func testReplayingFinishedExcerptIgnoresOldEndTickWhileSeeking() async throws {
        player.play(recording: .morning, startTime: 300, endTime: 301.4)
        try await waitUntil("Excerpt should finish preparing") {
            self.player.duration > 0 && !self.player.isBuffering
        }
        player.seek(to: player.duration)
        try await Task.sleep(nanoseconds: 350_000_000)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.currentTime, 1.4, accuracy: 0.05)

        player.toggle()
        // Run the stale periodic callback before the asynchronous rewind can
        // complete. Previously this marked the new playback finished again.
        player.updateTime(301.4)
        XCTAssertTrue(player.isPlaying, "An old end tick must not cancel replay")
        XCTAssertEqual(player.currentTime, 0, accuracy: 0.05)

        try await waitUntil("Replay should advance after the rewind completes") {
            self.player.isPlaying && !self.player.isBuffering &&
                self.player.currentTime > 0.1 && self.player.currentTime < 5
        }
        XCTAssertEqual(player.recording, .morning)
        XCTAssertEqual(player.duration, 1.4, accuracy: 0.01)
        try await waitUntil("The replay should still finish at its normal boundary") {
            !self.player.isPlaying && abs(self.player.currentTime - 1.4) < 0.05
        }
        XCTAssertFalse(player.isBuffering)
        XCTAssertNil(player.errorMessage)
    }

    func testStoppingDuringLoadingCannotResurrectPlayback() async throws {
        player.play(recording: .morning)
        player.stop()
        try await Task.sleep(nanoseconds: 350_000_000)
        XCTAssertNil(player.recording)
        XCTAssertFalse(player.isPlaying)
        XCTAssertFalse(player.isBuffering)
        XCTAssertEqual(player.currentTime, 0)
        XCTAssertEqual(player.duration, 0)
        XCTAssertNil(player.errorMessage)
    }

    func testQuranHandoffClearsAdhkarBeforeAnyDeferredStreamingWork() async throws {
        player.play(recording: .morning)
        try await waitUntil("Adhkar should finish loading before handoff") {
            self.player.duration > 0 && !self.player.isBuffering
        }

        // Both calls are synchronous on the main actor. The Mushaf's start task is
        // canceled before it can run, so this test cannot fetch any remote audio.
        let mushaf = MushafPlayer.shared
        mushaf.play(from: "1:1")
        XCTAssertEqual(mushaf.playingKey, "1:1")
        XCTAssertNil(player.recording)
        XCTAssertFalse(player.isPlaying)
        mushaf.stop()

        try await Task.sleep(nanoseconds: 350_000_000)
        XCTAssertNil(mushaf.playingKey)
        XCTAssertFalse(mushaf.isPlaying)
        XCTAssertNil(player.recording)
        XCTAssertEqual(player.duration, 0)
    }

    func testChapterPublishesItsTitleAndTheHaneenArtwork() async throws {
        let chapter = try XCTUnwrap(AdhkarRecording.morning.chapters.first)
        player.play(recording: .morning, startTime: chapter.start, endTime: chapter.end)
        try await waitUntil("Chapter should prepare its playback metadata") {
            self.player.duration > 0 && !self.player.isBuffering
        }
        let language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: SettingsKeys.appLanguage) ?? "") ?? .english
        let info = try XCTUnwrap(MPNowPlayingInfoCenter.default().nowPlayingInfo)
        XCTAssertEqual(info[MPMediaItemPropertyTitle] as? String, chapter.title(language))
        XCTAssertEqual(info[MPMediaItemPropertyAlbumTitle] as? String, "Haneen")
        let artwork = try XCTUnwrap(info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        XCTAssertGreaterThan(try XCTUnwrap(artwork.image(at: CGSize(width: 300, height: 300))).size.width, 0)
        XCTAssertNotNil(HaneenNowPlaying.image)

        player.pause()
        XCTAssertEqual(MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 0)
        player.stop()
        XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
    }

    func testSituationPlaybackPausesWithoutLosingItsReaderAndHandsOffCleanly() async throws {
        let situation = try XCTUnwrap(SituationCatalog.by(id: "beforeMarriage"))
        let audio = try XCTUnwrap(Bundle.main.url(forResource: "adhkar-morning", withExtension: "mp3"))
        let recitation = RecitationPlayer.shared
        recitation.play(situation: situation, sourceURLs: Array(repeating: audio, count: situation.verses.count))
        try await waitUntil("Situation recitation should begin from the local test source") {
            recitation.currentTime > 0.05
        }
        XCTAssertEqual(HaneenPlaybackPresence.shared.source, .situation)
        XCTAssertNotNil(MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork])
        recitation.pause()
        XCTAssertEqual(recitation.playingID, situation.id)
        XCTAssertEqual(recitation.situation, situation)
        XCTAssertFalse(recitation.isPlaying)
        recitation.resume()
        XCTAssertTrue(recitation.isPlaying)

        player.play(recording: .evening)
        XCTAssertNil(recitation.playingID, "Only the new playback source may own the session")
        XCTAssertFalse(recitation.isPlaying)
        XCTAssertEqual(HaneenPlaybackPresence.shared.source, .adhkar)
        try await waitUntil("Adhkar should own Now Playing after the switch") {
            self.player.duration > 0 && !self.player.isBuffering
        }
        recitation.stop()
        XCTAssertNotNil(MPNowPlayingInfoCenter.default().nowPlayingInfo,
                        "A stale stop on the old source must not erase the new source’s metadata")
        player.stop()
        XCTAssertNil(HaneenPlaybackPresence.shared.source)
    }

    func testFailedMushafAyahStopsRepeatAndKeepsAnActionableError() async throws {
        let mushaf = MushafPlayer.shared
        let wasRepeating = mushaf.repeatCurrent
        defer { mushaf.repeatCurrent = wasRepeating }
        mushaf.repeatCurrent = true
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-quran-\(UUID().uuidString).mp3")
        mushaf.play(from: "1:1", sourceURL: missing)
        try await waitUntil("Missing audio should report failure instead of endlessly repeating") {
            mushaf.errorMessage != nil
        }
        XCTAssertNil(mushaf.playingKey)
        XCTAssertFalse(mushaf.isPlaying)
        XCTAssertFalse(mushaf.isBuffering)
        XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
        XCTAssertEqual(HaneenPlaybackPresence.shared.failure?.source, .quran)
        XCTAssertEqual(HaneenPlaybackPresence.shared.failure?.message, mushaf.errorMessage)
        try await Task.sleep(nanoseconds: 350_000_000)
        XCTAssertNil(mushaf.playingKey, "A queued callback must not restart the failed ayah")
        XCTAssertNotNil(mushaf.errorMessage)
        HaneenPlaybackPresence.shared.clearFailure()
        XCTAssertNil(mushaf.errorMessage)
        XCTAssertNil(HaneenPlaybackPresence.shared.failure)
    }

    func testFailedSituationRecitationIsVisibleAfterItsPlayerDisappears() async throws {
        let situation = try XCTUnwrap(SituationCatalog.by(id: "beforeMarriage"))
        let recitation = RecitationPlayer.shared
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-situation-\(UUID().uuidString).mp3")
        recitation.play(situation: situation, sourceURLs: Array(repeating: missing, count: situation.verses.count))
        try await waitUntil("Missing situation audio should publish its error") {
            recitation.errorMessage != nil
        }
        XCTAssertNil(recitation.playingID)
        XCTAssertFalse(recitation.isPlaying)
        XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
        XCTAssertNil(HaneenPlaybackPresence.shared.source)
        XCTAssertEqual(HaneenPlaybackPresence.shared.failure?.source, .situation)
        XCTAssertEqual(HaneenPlaybackPresence.shared.failure?.message, recitation.errorMessage)
        HaneenPlaybackPresence.shared.clearFailure()
        XCTAssertNil(recitation.errorMessage)
        XCTAssertNil(HaneenPlaybackPresence.shared.failure)
    }

    private func assertBundledAsset(_ recording: AdhkarRecording,
                                    expectedDuration: TimeInterval) async throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "adhkar-\(recording.rawValue)",
                                               withExtension: "mp3"))
        XCTAssertTrue(url.isFileURL)
        let asset = AVURLAsset(url: url)
        let playable = try await asset.load(.isPlayable)
        let duration = try await asset.load(.duration).seconds
        XCTAssertTrue(playable, "The shipped MP3 must be decodable by AVFoundation")
        XCTAssertEqual(duration, expectedDuration, accuracy: 0.2)
    }

    private func waitUntil(_ description: String, timeout: TimeInterval = 5,
                           condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if let message = player.errorMessage {
                XCTFail("\(description): \(message)")
                throw PlaybackWaitFailure.failed
            }
            guard Date() < deadline else {
                XCTFail("\(description) timed out after \(timeout) seconds")
                throw PlaybackWaitFailure.timedOut
            }
            try await Task.sleep(nanoseconds: 25_000_000)
        }
    }

    private enum PlaybackWaitFailure: Error { case failed, timedOut }
}
