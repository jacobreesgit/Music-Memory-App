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
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // Regular items
                    ForEach(Array(recentlyAdded.prefix(5).enumerated()), id: \.element.persistentID) { index, song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            VStack(spacing: 8) {
                                // Artwork or placeholder
                                if let artwork = song.artwork {
                                    Image(uiImage: artwork.image(at: CGSize(width: 100, height: 100)) ?? UIImage(systemName: "music.note")!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(AppStyles.cornerRadius)
                                } else {
                                    Image(systemName: "music.note")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .padding(10)
                                        .background(AppStyles.secondaryColor)
                                        .cornerRadius(AppStyles.cornerRadius)
                                        .frame(width: 100, height: 100)
                                }
                                
                                // Title
                                Text(song.title ?? "Unknown")
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                
                                // Artist
                                Text(song.artist ?? "Unknown")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                // Days ago
                                Text(daysAgo(song.dateAdded))
                                    .font(.caption2)
                                    .foregroundColor(AppStyles.accentColor)
                            }
                            .frame(width: 100)
                        }
                    }
                    
                    // "See All" item
                    NavigationLink(destination: RecentlyAddedSongsView()) {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(AppStyles.secondaryColor)
                                    .frame(width: 100, height: 100)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "arrow.right.circle")
                                        .font(.system(size: 30))
                                        .foregroundColor(AppStyles.accentColor)
                                    
                                    Text("See All")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppStyles.accentColor)
                                }
                            }
                            .frame(width: 100, height: 100)
                            
                            // Empty space to match layout of other items
                            Spacer().frame(height: 18)
                            Spacer().frame(height: 16)
                            Spacer().frame(height: 14)
                        }
                        .frame(width: 100)
                    }
                }
                .padding(.horizontal)
            }
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
