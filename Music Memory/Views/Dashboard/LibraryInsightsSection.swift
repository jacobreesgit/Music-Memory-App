//
//  LibraryInsightsSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer

struct LibraryInsightsSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Library Insights")
                .font(AppStyles.headlineStyle)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                // Unplayed songs
                InsightRow(
                    icon: "exclamationmark.circle.fill",
                    color: .orange,
                    title: "Unplayed Songs",
                    value: "\(unplayedSongs) songs (\(unplayedPercentage)% of library)"
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Most recently played
                InsightRow(
                    icon: "calendar",
                    color: .blue,
                    title: "Most Recent Activity",
                    value: mostRecentActivity
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Era distribution
                InsightRow(
                    icon: "clock.arrow.circlepath",
                    color: AppStyles.accentColor,
                    title: "Favorite Era",
                    value: favoriteEra
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Longest song
                InsightRow(
                    icon: "timer",
                    color: .green,
                    title: "Longest Song",
                    value: longestSongInfo
                )
            }
            .padding()
            .background(AppStyles.secondaryColor.opacity(0.3))
            .cornerRadius(AppStyles.cornerRadius)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Computed Properties
    
    // Count of songs with 0 plays
    private var unplayedSongs: Int {
        musicLibrary.songs.filter { $0.playCount == 0 }.count
    }
    
    // Percentage of library that's unplayed
    private var unplayedPercentage: Int {
        if musicLibrary.songs.isEmpty {
            return 0
        }
        
        return Int((Double(unplayedSongs) / Double(musicLibrary.songs.count) * 100).rounded())
    }
    
    // Most recent activity based on last played date
    private var mostRecentActivity: String {
        if let lastPlayed = musicLibrary.songs.compactMap({ $0.lastPlayedDate }).max() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: lastPlayed)
        }
        
        return "No recent activity data"
    }
    
    // Favorite era based on song release years
    private var favoriteEra: String {
        var decadeCounts: [String: Int] = [:]
        
        for song in musicLibrary.songs where song.playCount > 0 {
            if let releaseDate = song.releaseDate {
                let year = Calendar.current.component(.year, from: releaseDate)
                let decade = "\(year / 10 * 10)s"
                decadeCounts[decade, default: 0] += song.playCount
            }
        }
        
        if let topDecade = decadeCounts.max(by: { $0.value < $1.value }) {
            return "\(topDecade.key) (\(topDecade.value) plays)"
        }
        
        return "Unknown"
    }
    
    // Longest song info
    private var longestSongInfo: String {
        if let longestSong = musicLibrary.songs.max(by: { $0.playbackDuration < $1.playbackDuration }) {
            let minutes = Int(longestSong.playbackDuration / 60)
            let seconds = Int(longestSong.playbackDuration.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        
        return "None found"
    }
}
