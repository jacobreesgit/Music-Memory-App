//
//  DashboardSummaryView.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer
import Charts

struct DashboardSummaryView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header title
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
                    
                    // Library diversity
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
                }
                .padding(.horizontal)
            }
            
            // Navigation Buttons with fixed width to match other elements
            VStack(spacing: 12) {
                // Analytics button
                NavigationLink(destination: ListeningAnalyticsView()) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Analytics")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Deep dive into your listening habits")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(AppStyles.accentColor.gradient)
                    .cornerRadius(AppStyles.cornerRadius)
                }
                .frame(maxWidth: .infinity)
                
                // Timeline button
                NavigationLink(destination: ListeningTimelineView()) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Timeline")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("See your listening history")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(AppStyles.accentColor.gradient)
                    .cornerRadius(AppStyles.cornerRadius)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            // Genre distribution
            if !topGenres.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Genres")
                        .font(AppStyles.headlineStyle)
                        .padding(.horizontal)
                    
                    // Genre chart
                    HStack(alignment: .center) {
                        // Pie chart
                        ZStack {
                            ForEach(Array(topGenres.prefix(5).enumerated()), id: \.element.id) { index, genre in
                                Circle()
                                    .trim(from: index == 0 ? 0 : segmentStartAngle(index),
                                          to: segmentEndAngle(index + 1))
                                    .stroke(colorForIndex(index), lineWidth: 25)
                                    .frame(width: 100)
                                    .rotationEffect(.degrees(-90))
                            }
                            
                            VStack {
                                Text("\(topGenres.count)")
                                    .font(.system(size: 20, weight: .bold))
                                Text("genres")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 150, height: 150)
                        .padding(.leading)
                        
                        // Legend
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(topGenres.prefix(3).enumerated()), id: \.element.id) { index, genre in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(colorForIndex(index))
                                        .frame(width: 10, height: 10)
                                    
                                    Text(genre.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text("\(Int((Double(genre.totalPlayCount) / Double(totalGenrePlays) * 100).rounded()))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if topGenres.count > 3 {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 10, height: 10)
                                    
                                    Text("Other")
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text("\(otherGenresPercentage)%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.trailing)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                    .background(AppStyles.secondaryColor.opacity(0.3))
                    .cornerRadius(AppStyles.cornerRadius)
                    .padding(.horizontal)
                }
            }
            
            // Library Insights
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
                    
                    // Most active day
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
        .padding(.bottom, 20)
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
    
    // Top genres sorted by play count
    private var topGenres: [GenreData] {
        musicLibrary.genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Total plays across top genres for percentage calculation
    private var totalGenrePlays: Int {
        topGenres.prefix(5).reduce(0) { $0 + $1.totalPlayCount }
    }
    
    // Percentage of plays from genres other than top 3
    private var otherGenresPercentage: Int {
        let top3Plays = topGenres.prefix(3).reduce(0) { $0 + $1.totalPlayCount }
        let otherPlays = totalGenrePlays - top3Plays
        return Int((Double(otherPlays) / Double(totalGenrePlays) * 100).rounded())
    }
    
    // Helper function to get start angle for pie chart segment
    private func segmentStartAngle(_ index: Int) -> CGFloat {
        let totalPlays = totalGenrePlays
        let previousTotal = topGenres.prefix(index).reduce(0) { $0 + $1.totalPlayCount }
        return CGFloat(previousTotal) / CGFloat(totalPlays)
    }
    
    // Helper function to get end angle for pie chart segment
    private func segmentEndAngle(_ index: Int) -> CGFloat {
        let totalPlays = totalGenrePlays
        let previousTotal = topGenres.prefix(index).reduce(0) { $0 + $1.totalPlayCount }
        return CGFloat(previousTotal) / CGFloat(totalPlays)
    }
    
    // Helper function to get color for a genre index
    private func colorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [
            AppStyles.accentColor,
            Color.blue,
            Color.green,
            Color.orange,
            Color.red
        ]
        
        return index < colors.count ? colors[index] : Color.gray
    }
    
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
        
        return "No recent activity"
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

// MARK: - Helper Components

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

// Row for displaying a specific insight with icon
struct InsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}
