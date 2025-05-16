//
//  Music_MemoryApp.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//  Updated to support widget data sharing and detail view navigation
//

import SwiftUI
import MediaPlayer
import WidgetKit

@main
struct MusicMemoryApp: App {
    @StateObject private var musicLibrary = MusicLibraryModel()
    @State private var selectedTabIndex: Int = 0  // Track main tab selection
    @State private var selectedLibraryTab: Int = 0  // Track library tab selection
    @State private var navigateToDetailItem: (type: String, id: String)? = nil  // For detail navigation
    
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
                            
                            // Check if we have an item ID (for direct navigation to detail view)
                            if pathComponents.count > 2 {
                                let itemId = pathComponents[2]
                                
                                // Set the navigation target
                                navigateToDetailItem = (type: contentType, id: itemId)
                                
                                // First navigate to the correct library tab
                                selectedTabIndex = 1 // Switch to Library tab
                                
                                // Then select the appropriate sub-tab
                                switch contentType {
                                case "songs":
                                    selectedLibraryTab = 0 // Songs tab
                                case "artists":
                                    selectedLibraryTab = 1 // Artists tab
                                case "albums":
                                    selectedLibraryTab = 2 // Albums tab
                                case "genres":
                                    selectedLibraryTab = 3 // Genres tab
                                case "playlists":
                                    selectedLibraryTab = 4 // Playlists tab
                                default:
                                    selectedLibraryTab = 0 // Default to Songs tab
                                }
                                
                                // The actual navigation to detail view will happen in ContentView
                                // or LibraryView using these state variables
                                print("Navigating to \(contentType) detail view for item ID: \(itemId)")
                            } else {
                                // Navigate to the appropriate library tab without detail view
                                selectedTabIndex = 1 // Switch to Library tab
                                
                                switch contentType {
                                case "songs":
                                    selectedLibraryTab = 0 // Songs tab
                                case "artists":
                                    selectedLibraryTab = 1 // Artists tab
                                case "albums":
                                    selectedLibraryTab = 2 // Albums tab
                                case "genres":
                                    selectedLibraryTab = 3 // Genres tab
                                case "playlists":
                                    selectedLibraryTab = 4 // Playlists tab
                                default:
                                    selectedLibraryTab = 0 // Default to Songs tab
                                }
                                
                                print("Navigating to \(contentType) tab")
                            }
                        }
                    }
                }
                // Pass state variables to ContentView
                .environment(\.selectedTabIndex, selectedTabIndex)
                .environment(\.selectedLibraryTab, selectedLibraryTab)
                .environment(\.navigateToDetailItem, navigateToDetailItem)
        }
    }
}

// Environment keys for passing navigation state
struct SelectedTabIndexKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

struct SelectedLibraryTabKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

struct NavigateToDetailItemKey: EnvironmentKey {
    static let defaultValue: (type: String, id: String)? = nil
}

extension EnvironmentValues {
    var selectedTabIndex: Int {
        get { self[SelectedTabIndexKey.self] }
        set { self[SelectedTabIndexKey.self] = newValue }
    }
    
    var selectedLibraryTab: Int {
        get { self[SelectedLibraryTabKey.self] }
        set { self[SelectedLibraryTabKey.self] = newValue }
    }
    
    var navigateToDetailItem: (type: String, id: String)? {
        get { self[NavigateToDetailItemKey.self] }
        set { self[NavigateToDetailItemKey.self] = newValue }
    }
}
