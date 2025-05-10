//
//  Music_MemoryApp.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

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
        }
    }
}
