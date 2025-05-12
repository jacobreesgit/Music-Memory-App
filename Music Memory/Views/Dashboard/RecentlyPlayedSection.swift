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
        VStack(alignment: .leading, spacing: 16) {
            if let recentlyPlayed = getRecentlyPlayedSongs(), !recentlyPlayed.isEmpty {
                Text("Recently Played")
                    .font(.system(size: 24, weight: .bold)) 
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        // Regular items
                        ForEach(recentlyPlayed.prefix(5), id: \.persistentID) { song in
                            NavigationLink(destination: SongDetailView(song: song)) {
                                VStack {
                                    // Artwork or placeholder without rank badge
                                    if let artwork = song.artwork {
                                        Image(uiImage: artwork.image(at: CGSize(width: 100, height: 100)) ?? UIImage(systemName: "music.note")!)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
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
                                    }
                                    
                                    // Title
                                    Text(song.title ?? "Unknown")
                                        .font(AppStyles.bodyStyle)
                                        .lineLimit(1)
                                        .foregroundColor(.primary)
                                    
                                    // Subtitle
                                    Text(song.artist ?? "Unknown")
                                        .font(AppStyles.captionStyle)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    // Play count
                                    Text("\(song.playCount ?? 0) plays")
                                        .font(AppStyles.captionStyle)
                                        .foregroundColor(AppStyles.accentColor)
                                }
                                .frame(width: 100)
                            }
                        }
                        
                        // "See All" item
                        NavigationLink(destination: RecentlyPlayedSongsView()) {
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
