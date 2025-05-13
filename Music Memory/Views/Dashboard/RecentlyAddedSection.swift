//
//  RecentlyAddedSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 12/05/2025.
//

import SwiftUI
import MediaPlayer

struct RecentlyAddedSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        let recentlyAdded = getRecentlyAddedSongs()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Recently Added")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            TopItemsView(
                title: "",
                items: recentlyAdded,
                artwork: { $0.artwork },
                itemTitle: { $0.title ?? "Unknown" },
                itemSubtitle: { $0.artist ?? "Unknown" },
                itemPlays: { _ in 0 },  // Not used when customPlayLabel is provided
                iconName: { _ in "music.note" },
                destination: { song, _ in SongDetailView(song: song) },
                seeAllDestination: { RecentlyAddedSongsView() },
                customPlayLabel: { song in daysAgo(song.dateAdded) },
                showRank: false
            )
        }
    }
    
    // Helper function to get recently added songs
    private func getRecentlyAddedSongs() -> [MPMediaItem] {
        return musicLibrary.songs.sorted { $0.dateAdded > $1.dateAdded }.prefix(8).map { $0 }
    }
    
    // Helper to format days ago
    private func daysAgo(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        let days = Int(timeInterval / 86400)
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks)w ago"
        } else if days < 365 {
            let months = days / 30
            return "\(months)mo ago"
        } else {
            let years = days / 365
            return "\(years)y ago"
        }
    }
}
