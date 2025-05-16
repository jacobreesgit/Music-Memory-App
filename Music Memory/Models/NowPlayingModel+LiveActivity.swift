// Fixed NowPlayingModel+LiveActivity.swift

import ActivityKit
import MediaPlayer
import SwiftUI

extension NowPlayingModel {
    // Static property to track the current activity across the app lifecycle
    private static var currentActivity: Activity<NowPlayingAttributes>? = nil
    
    // Start or update the Dynamic Island Live Activity
    func updateDynamicIsland() {
        guard let currentSong = currentSong else {
            // End activity if no song is playing
            endActivity()
            return
        }
        
        // Find song rank - use a simpler approach based on the current song context
        let songRank = findSongRank(currentSong)
        
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
            // Update existing activity - using the non-deprecated method
            Task {
                await activity.update(contentState)
            }
        } else {
            // Start new activity only if one doesn't exist
            if ActivityAuthorizationInfo().areActivitiesEnabled {
                do {
                    let attributes = NowPlayingAttributes()
                    NowPlayingModel.currentActivity = try Activity.request(
                        attributes: attributes,
                        content: contentState
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
    
    // Helper function to estimate song rank based on play count
    private func findSongRank(_ song: MPMediaItem) -> Int {
        guard let currentPlayCount = song.value(forProperty: MPMediaItemPropertyPlayCount) as? Int else {
            return 1 // Default rank if no play count
        }
        
        // We'll use an estimation approach since we can't directly access the sorted library
        // This is an estimate based on the song's play count.
        // For most apps, higher play counts mean higher ranks (lower number)
        
        // If it's a highly played song (100+ plays), it's probably in the top 10
        if currentPlayCount > 100 {
            return max(1, min(5, 101 - currentPlayCount / 20))
        }
        // Medium play count (30-99)
        else if currentPlayCount > 30 {
            return max(5, min(20, 100 - currentPlayCount))
        }
        // Lower play count
        else {
            return max(20, 100 - currentPlayCount * 3)
        }
    }
}
