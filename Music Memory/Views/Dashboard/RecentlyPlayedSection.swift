//
//  RecentlyPlayedSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 12/05/2025.
//

import SwiftUI
import MediaPlayer

struct RecentlyPlayedSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        if let recentlyPlayed = getRecentlyPlayedSongs(), !recentlyPlayed.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recently Played")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                TopItemsView(
                    title: "",
                    items: recentlyPlayed,
                    artwork: { $0.artwork },
                    itemTitle: { $0.title ?? "Unknown" },
                    itemSubtitle: { $0.artist ?? "Unknown" },
                    itemPlays: { $0.playCount },
                    iconName: { _ in "music.note" },
                    destination: { song, _ in SongDetailView(song: song) },
                    seeAllDestination: {
                        LibraryView(
                            selectedTab: .constant(0),
                            initialSongsSortOption: .recentlyPlayed,
                            initialSongsSortAscending: false
                        )
                    },
                    customPlayLabel: { song in "\(song.playCount) plays" },
                    showRank: false
                )
            }
        }
    }
    
    // Helper function to get recently played songs
    private func getRecentlyPlayedSongs() -> [MPMediaItem]? {
        let songsWithLastPlayed = musicLibrary.songs.filter { $0.lastPlayedDate != nil }
            .sorted { $0.lastPlayedDate! > $1.lastPlayedDate! }
        
        guard !songsWithLastPlayed.isEmpty else { return nil }
        return Array(songsWithLastPlayed.prefix(5))
    }
    
    // Helper function to format time ago
    private func lastPlayedTimeAgo(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}
