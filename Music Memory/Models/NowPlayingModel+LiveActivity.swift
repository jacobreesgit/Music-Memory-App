// NowPlayingModel+LiveActivity.swift
// Add this file to the Models folder

import ActivityKit
import MediaPlayer
import SwiftUI

extension NowPlayingModel {
    // Track the current live activity
    private struct LiveActivityState {
        static var currentActivity: Activity<NowPlayingAttributes>? = nil
    }
    
    // Start or update the Dynamic Island Live Activity
    func updateDynamicIsland() {
        guard let currentSong = currentSong else {
            // End activity if no song is playing
            endActivity()
            return
        }
        
        // Get artwork data
        var artworkData: Data? = nil
        if let artwork = artworkImage {
            artworkData = artwork.pngData()
        }
        
        // Create content state
        let contentState = NowPlayingAttributes.ContentState(
            title: currentSong.title ?? "Unknown",
            artist: currentSong.artist ?? "Unknown Artist",
            playCount: currentSong.playCount,
            playbackProgress: playbackProgress,
            isPlaying: isPlaying,
            artworkData: artworkData
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
    private func endActivity() {
        Task {
            await LiveActivityState.currentActivity?.end(dismissalPolicy: .immediate)
            LiveActivityState.currentActivity = nil
        }
    }
}
