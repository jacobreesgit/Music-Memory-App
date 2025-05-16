// Updated NowPlayingAttributes.swift with song rank

import ActivityKit
import SwiftUI

public struct NowPlayingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String
        public var artist: String
        public var playCount: Int
        public var playbackProgress: Double
        public var isPlaying: Bool
        public var songRank: Int  // Added song rank property
        public var artworkData: Data? // Keep this but we won't use it
        
        public init(title: String, artist: String, playCount: Int, playbackProgress: Double, isPlaying: Bool, songRank: Int = 1, artworkData: Data? = nil) {
            self.title = title
            self.artist = artist
            self.playCount = playCount
            self.playbackProgress = playbackProgress
            self.isPlaying = isPlaying
            self.songRank = songRank  // Store the song rank
            self.artworkData = nil // Always set to nil to avoid payload issues
        }
    }
    
    public init() { }
}
