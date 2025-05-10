//
//  LibraryOverviewSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer
import Charts

struct LibraryOverviewSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Library Overview")
                .sectionHeaderStyle()
            
            // Library growth chart
            libraryGrowthChart
            
            // Library stats
            libraryStatsCards
            
            // Recently added highly-played songs
            recentlyAddedHighlyPlayedSection
        }
    }
    
    private var libraryGrowthChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Library Growth")
                .font(.subheadline)
                .foregroundColor(AppStyles.accentColor)
            
            if !libraryGrowthData.isEmpty {
                Chart {
                    ForEach(libraryGrowthData, id: \.month) { data in
                        BarMark(
                            x: .value("Month", data.month),
                            y: .value("Songs", data.count)
                        )
                        .foregroundStyle(AppStyles.accentColor.gradient)
                    }
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
            } else {
                Text("Not enough date added information available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
        .padding(.horizontal)
    }
    
    private var libraryStatsCards: some View {
        HStack(spacing: 12) {
            // Unplayed songs
            StatCard(
                title: "Unplayed Songs",
                value: "\(unplayedSongs)",
                subtitle: "\(unplayedPercentage)% of library",
                icon: "exclamationmark.circle.fill",
                color: .orange
            )
            
            // Average plays per song
            StatCard(
                title: "Average Plays",
                value: String(format: "%.1f", averagePlaysPerSong),
                subtitle: "per song",
                icon: "repeat",
                color: AppStyles.accentColor
            )
        }
        .padding(.horizontal)
    }
    
    private var recentlyAddedHighlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Discoveries")
                .font(.subheadline)
                .foregroundColor(AppStyles.accentColor)
            
            if !recentlyAddedHighlyPlayed.isEmpty {
                ForEach(Array(recentlyAddedHighlyPlayed.enumerated()), id: \.element.persistentID) { index, song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        HStack(spacing: 10) {
                            SongRow(song: song)
                            
                            // Play rate indicator
                            VStack(alignment: .trailing) {
                                Text(String(format: "%.1f", playRateForSong(song)))
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                                Text("plays/day")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if index < recentlyAddedHighlyPlayed.count - 1 {
                        Divider()
                            .padding(.leading, 70)
                    }
                }
            } else {
                Text("No highly-played recent additions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var libraryGrowthData: [LibraryGrowthData] {
        var growthData: [String: Int] = [:]
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        for song in musicLibrary.songs {
            if let dateAdded = song.dateAdded {
                let monthKey = formatter.string(from: dateAdded)
                growthData[monthKey, default: 0] += 1
            }
        }
        
        // Convert to array and sort by date
        return growthData.compactMap { month, count in
            guard let date = formatter.date(from: month) else { return nil }
            return LibraryGrowthData(month: month, count: count, date: date)
        }
        .sorted { $0.date < $1.date }
        .suffix(12) // Show last 12 months
    }
    
    private var unplayedSongs: Int {
        musicLibrary.songs.filter { $0.playCount == 0 }.count
    }
    
    private var unplayedPercentage: Int {
        guard !musicLibrary.songs.isEmpty else { return 0 }
        return Int((Double(unplayedSongs) / Double(musicLibrary.songs.count) * 100).rounded())
    }
    
    private var averagePlaysPerSong: Double {
        guard !musicLibrary.songs.isEmpty else { return 0 }
        let totalPlays = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        return Double(totalPlays) / Double(musicLibrary.songs.count)
    }
    
    private var recentlyAddedHighlyPlayed: [MPMediaItem] {
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date())!
        
        return musicLibrary.songs
            .filter { song in
                guard let dateAdded = song.dateAdded,
                      dateAdded > threeMonthsAgo,
                      song.playCount > 5 else { return false }
                return true
            }
            .sorted { playRateForSong($0) > playRateForSong($1) }
            .prefix(3)
            .map { $0 }
    }
    
    private func playRateForSong(_ song: MPMediaItem) -> Double {
        guard let dateAdded = song.dateAdded else { return 0 }
        let daysSinceAdded = Date().timeIntervalSince(dateAdded) / (60 * 60 * 24)
        return Double(song.playCount) / max(1, daysSinceAdded)
    }
}
