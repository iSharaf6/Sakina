import MediaPlayer
import UIKit

/// The same opaque artwork as the installed icon, shared by every playback source.
/// Cache it once rather than decoding the 1024 px image on each metadata update.
@MainActor
enum HaneenNowPlaying {
    static let image = UIImage(named: "HaneenNowPlaying")
    static let artwork: MPMediaItemArtwork? = image.map { image in
        MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }

    static func publish(_ metadata: [String: Any]) {
        var info = metadata
        info[MPMediaItemPropertyAlbumTitle] = "Haneen"
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        if let artwork { info[MPMediaItemPropertyArtwork] = artwork }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
