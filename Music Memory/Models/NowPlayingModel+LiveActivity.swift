// NowPlayingModel+LiveActivity.swift - Minimalist version
import ActivityKit
import MediaPlayer
import SwiftUI

extension NowPlayingModel {
    // Track the current live activity
    private struct LiveActivityState {
        static var currentActivity: Activity<NowPlayingAttributes>? = nil
    }
    
    // Start or update the Dynamic Island Live Activity - Focused only on play count
    func updateDynamicIsland() {
        guard let currentSong = currentSong else {
            // End activity if no song is playing
            endActivity()
            return
        }
        
        // Ultra-minimal content state - just what we need for the play count
        let contentState = NowPlayingAttributes.ContentState(
            title: currentSong.title ?? "Unknown",
            artist: currentSong.artist ?? "Unknown Artist",
            playCount: currentSong.playCount,
            playbackProgress: playbackProgress,
            isPlaying: isPlaying,
            // No artwork at all to keep payload tiny
            artworkData: nil
        )
        
        if let activity = LiveActivityState.currentActivity {
            // Update existing activity
            Task {
                await activity.update(using: contentState)
            }
        } else {
            // Start new activity if supported
            if ActivityAuthorizationInfo().areActivitiesEnabled {
                do {
                    let attributes = NowPlayingAttributes()
                    LiveActivityState.currentActivity = try Activity.request(
                        attributes: attributes,
                        contentState: contentState
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
            await LiveActivityState.currentActivity?.end(dismissalPolicy: ActivityUIDismissalPolicy.immediate)
            LiveActivityState.currentActivity = nil
        }
    }
}
