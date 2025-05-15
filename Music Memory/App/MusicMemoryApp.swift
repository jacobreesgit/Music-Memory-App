//
//  Music_MemoryApp.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//  Updated to support widget data sharing
//

import SwiftUI
import MediaPlayer
import WidgetKit

@main
struct MusicMemoryApp: App {
    @StateObject private var musicLibrary = MusicLibraryModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(musicLibrary)
                .onAppear {
                    // Request permission and load data when app opens
                    musicLibrary.requestPermissionAndLoadLibrary()
                    
                    // Request Apple Music authorization simultaneously
                    Task {
                        let status = await AppleMusicManager.shared.requestAuthorization()
                        
                        // If authorized, check subscription status
                        if status == .authorized {
                            await MainActor.run {
                                AppleMusicManager.shared.checkSubscriptionStatus()
                            }
                        }
                    }
                }
                .onChange(of: musicLibrary.filteredSongs) { oldValue, newValue in
                    // Update widget data when library changes
                    musicLibrary.updateWidgetData()
                }
                .onOpenURL { url in
                    // Handle widget deep links
                    if url.scheme == "musicmemory", url.host == "highlights" {
                        // Extract the content type from the path
                        let pathComponents = url.pathComponents
                        if pathComponents.count > 1 {
                            let contentType = pathComponents[1]
                            // Navigate to the appropriate library tab
                            switch contentType {
                            case "songs":
                                // Navigate to songs tab
                                print("Navigate to songs tab")
                            case "artists":
                                // Navigate to artists tab
                                print("Navigate to artists tab")
                            case "albums":
                                // Navigate to albums tab
                                print("Navigate to albums tab")
                            case "playlists":
                                // Navigate to playlists tab
                                print("Navigate to playlists tab")
                            default:
                                break
                            }
                        }
                    }
                }
        }
    }
}
