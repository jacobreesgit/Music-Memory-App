//
//  SummaryStatsSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer

struct SummaryStatsSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Music Summary")
                .font(AppStyles.headlineStyle)
                .foregroundColor(AppStyles.accentColor)
                .padding(.horizontal)
            
            // Stats Cards in a horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Total listening time
                    SummaryStatCard(
                        title: "Total Listening",
                        value: formattedTotalListeningTime,
                        icon: "clock.fill"
                    )
                    
                    // Total number of plays
                    SummaryStatCard(
                        title: "Total Plays",
                        value: "\(totalPlays)",
                        icon: "play.circle.fill"
                    )
                    
                    // Library size
                    SummaryStatCard(
                        title: "Library Size",
                        value: "\(musicLibrary.songs.count) songs",
                        icon: "music.note.list"
                    )
                    
                    // Average plays per song
                    SummaryStatCard(
                        title: "Avg. Plays",
                        value: "\(averagePlaysPerSong)",
                        icon: "chart.bar.fill"
                    )
                    
                    // Unplayed songs
                    SummaryStatCard(
                        title: "Unplayed",
                        value: "\(unplayedCount) songs",
                        icon: "play.slash"
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    // Calculate total listening time
    private var totalListeningTimeSeconds: TimeInterval {
        var total: TimeInterval = 0
        
        for song in musicLibrary.songs {
            total += song.playbackDuration * Double(song.playCount)
        }
        
        return total
    }
    
    // Format the total listening time nicely
    private var formattedTotalListeningTime: String {
        let totalSeconds = Int(totalListeningTimeSeconds)
        let hours = totalSeconds / 3600
        
        if hours > 24 {
            let days = hours / 24
            return "\(days) days"
        } else {
            return "\(hours) hrs"
        }
    }
    
    // Total play count across all songs
    private var totalPlays: Int {
        musicLibrary.songs.reduce(0) { $0 + $1.playCount }
    }
    
    // Average plays per song
    private var averagePlaysPerSong: String {
        if musicLibrary.songs.isEmpty {
            return "0"
        }
        
        let average = Double(totalPlays) / Double(musicLibrary.songs.count)
        return String(format: "%.1f", average)
    }
    
    // Count of unplayed songs
    private var unplayedCount: Int {
        musicLibrary.songs.filter { $0.playCount == 0 }.count
    }
}

// Card for displaying a statistic
struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppStyles.accentColor)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding()
        .frame(minWidth: 120, alignment: .leading)
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
    }
}
