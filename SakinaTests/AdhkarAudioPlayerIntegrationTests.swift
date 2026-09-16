import AVFoundation
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
