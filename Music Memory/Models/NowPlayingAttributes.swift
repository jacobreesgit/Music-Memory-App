import ActivityKit
import SwiftUI

public struct NowPlayingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String
        public var artist: String
        public var playCount: Int
        public var playbackProgress: Double
        public var isPlaying: Bool
        public var artworkData: Data? // Keep this but we won't use it
        
        public init(title: String, artist: String, playCount: Int, playbackProgress: Double, isPlaying: Bool, artworkData: Data? = nil) {
            self.title = title
            self.artist = artist
            self.playCount = playCount
            self.playbackProgress = playbackProgress
            self.isPlaying = isPlaying
            self.artworkData = nil // Always set to nil to avoid payload issues
        }
    }
    
    public init() { }
}
