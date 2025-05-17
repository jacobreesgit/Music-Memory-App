// NowPlayingModel+LiveActivity.swift - Fixed version

import ActivityKit
import MediaPlayer
import SwiftUI

extension NowPlayingModel {
    // Static property to track the current activity across the app lifecycle
    static var currentActivity: Activity<NowPlayingAttributes>? = nil
    
    // Start or update the Dynamic Island Live Activity
    func updateDynamicIsland() {
        guard let currentSong = currentSong else {
            // End activity if no song is playing
            endActivity()
            return
        }
        
        // Get the actual rank from the music library
        let songRank = findActualSongRank(currentSong)
        
        // Create content state with song info
        let contentState = NowPlayingAttributes.ContentState(
            title: currentSong.title ?? "Unknown",
            artist: currentSong.artist ?? "Unknown Artist",
            playCount: currentSong.playCount,
            playbackProgress: playbackProgress,
            isPlaying: isPlaying,
            songRank: songRank,
            artworkData: nil
        )
        
        // Check if we have an existing activity
        if let activity = NowPlayingModel.currentActivity {
            // Update existing activity with the correct syntax
            Task {
                await activity.update(using: contentState)
            }
        } else {
            // Start new activity only if one doesn't exist
            if ActivityAuthorizationInfo().areActivitiesEnabled {
                do {
                    let attributes = NowPlayingAttributes()
                    NowPlayingModel.currentActivity = try Activity.request(
                        attributes: attributes,
                        content: ActivityContent(state: contentState, staleDate: nil)
                    )
                } catch {
                    print("Error starting live activity: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // End the current activity
    func endActivity() {
        Task {
            // Use the non-deprecated method
            await NowPlayingModel.currentActivity?.end(dismissalPolicy: .immediate)
            NowPlayingModel.currentActivity = nil
        }
    }
    
    // Find the actual rank of a song in the library
    private func findActualSongRank(_ song: MPMediaItem) -> Int {
        // Safely unwrap the optional musicLibrary
        guard let musicLib = musicLibrary else {
            // If musicLibrary is not set yet, use a default rank
            return 1
        }
        
        // Get the sorted songs by play count
        let sortedSongs = musicLib.filteredSongs
        
        // Find the index of the current song in the sorted list
        if let index = sortedSongs.firstIndex(where: { $0.persistentID == song.persistentID }) {
            return index + 1 // +1 because ranks start at 1, not 0
        }
        
        // If song not found in the sorted list (rare case), find its rank by play count
        let playCount = song.playCount
        
        // Count how many songs have more plays than the current song
        let higherRankedSongs = sortedSongs.filter { $0.playCount > playCount }.count
        
        // Return rank (add 1 since ranks start at 1)
        return higherRankedSongs + 1
    }
}
