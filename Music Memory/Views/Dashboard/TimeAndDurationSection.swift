//
//  TimeAndDurationSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer
import Charts

struct TimeAndDurationSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time & Duration")
                .sectionHeaderStyle()
            
            // Total listening time
            totalListeningTimeCard
            
            // Duration distribution
            durationDistributionCharts
        }
    }
    
    private var totalListeningTimeCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Listening Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formattedTotalListeningTime)
                    .font(.system(size: 24, weight: .bold))
            }
            
            Spacer()
            
            Image(systemName: "clock.fill")
                .font(.system(size: 36))
                .foregroundColor(AppStyles.accentColor.opacity(0.7))
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
        .padding(.horizontal)
    }
    
    private var durationDistributionCharts: some View {
        VStack(spacing: 16) {
            // Song length distribution
            songLengthDistribution
            
            // Era distribution
            eraDistribution
        }
    }
    
    private var songLengthDistribution: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Song Length Distribution")
                .font(.subheadline)
                .foregroundColor(AppStyles.accentColor)
            
            Chart {
                ForEach(songLengthData, id: \.range) { item in
                    BarMark(
                        x: .value("Range", item.range),
                        y: .value("Count", item.count)
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
            
            // Length stats
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Shortest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(shortestSongInfo)
                        .font(.caption)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing) {
                    Text("Longest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(longestSongInfo)
                        .font(.caption)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
        .padding(.horizontal)
    }
    
    private var eraDistribution: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Music by Decade")
                .font(.subheadline)
                .foregroundColor(AppStyles.accentColor)
            
            if !eraData.isEmpty {
                Chart {
                    ForEach(Array(eraData.sorted(by: { $0.key < $1.key })), id: \.key) { decade, count in
                        BarMark(
                            x: .value("Decade", decade),
                            y: .value("Plays", count)
                        )
                        .foregroundStyle(AppStyles.accentColor.gradient)
                    }
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
            } else {
                Text("Not enough release date information available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var totalListeningTimeSeconds: TimeInterval {
        var total: TimeInterval = 0
        for song in musicLibrary.songs {
            total += song.playbackDuration * Double(song.playCount)
        }
        return total
    }
    
    private var formattedTotalListeningTime: String {
        let totalSeconds = Int(totalListeningTimeSeconds)
        let hours = totalSeconds / 3600
        
        if hours > 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return "\(days) days, \(remainingHours) hours"
        } else {
            let minutes = (totalSeconds % 3600) / 60
            return "\(hours) hours, \(minutes) minutes"
        }
    }
    
    private var songLengthData: [SongLengthRange] {
        var ranges: [String: Int] = [
            "< 2 min": 0,
            "2-3 min": 0,
            "3-4 min": 0,
            "4-5 min": 0,
            "5+ min": 0
        ]
        
        for song in musicLibrary.songs {
            let minutes = song.playbackDuration / 60
            
            if minutes < 2 {
                ranges["< 2 min"]! += 1
            } else if minutes < 3 {
                ranges["2-3 min"]! += 1
            } else if minutes < 4 {
                ranges["3-4 min"]! += 1
            } else if minutes < 5 {
                ranges["4-5 min"]! += 1
            } else {
                ranges["5+ min"]! += 1
            }
        }
        
        return [
            SongLengthRange(range: "< 2 min", count: ranges["< 2 min"] ?? 0),
            SongLengthRange(range: "2-3 min", count: ranges["2-3 min"] ?? 0),
            SongLengthRange(range: "3-4 min", count: ranges["3-4 min"] ?? 0),
            SongLengthRange(range: "4-5 min", count: ranges["4-5 min"] ?? 0),
            SongLengthRange(range: "5+ min", count: ranges["5+ min"] ?? 0)
        ]
    }
    
    struct SongLengthRange: Identifiable {
        let id = UUID()
        let range: String
        let count: Int
    }
    
    private var eraData: [String: Int] {
        var decadeCounts: [String: Int] = [:]
        
        for song in musicLibrary.songs where song.playCount > 0 {
            if let releaseDate = song.releaseDate {
                let year = Calendar.current.component(.year, from: releaseDate)
                let decade = "\(year / 10 * 10)s"
                decadeCounts[decade, default: 0] += song.playCount
            }
        }
        
        return decadeCounts
    }
    
    private var shortestSongInfo: String {
        if let shortestSong = musicLibrary.songs.min(by: { $0.playbackDuration < $1.playbackDuration }) {
            let minutes = Int(shortestSong.playbackDuration / 60)
            let seconds = Int(shortestSong.playbackDuration.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "N/A"
    }
    
    private var longestSongInfo: String {
        if let longestSong = musicLibrary.songs.max(by: { $0.playbackDuration < $1.playbackDuration }) {
            let minutes = Int(longestSong.playbackDuration / 60)
            let seconds = Int(longestSong.playbackDuration.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "N/A"
    }
}
