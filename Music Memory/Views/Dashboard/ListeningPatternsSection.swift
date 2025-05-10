//
//  ListeningPatternsSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer

struct ListeningPatternsSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Listening Patterns")
                .sectionHeaderStyle()
            
            // Repeat listening metrics
            repeatListeningMetrics
            
            // Artist variety visualization
            artistVarietySection
            
            // Album completion rate
            albumCompletionSection
        }
    }
    
    private var repeatListeningMetrics: some View {
        HStack(spacing: 12) {
            // Repeat score
            StatCard(
                title: "Repeat Score",
                value: "\(Int(repeatListeningScore * 100))",
                subtitle: repeatListeningDescription,
                icon: "repeat",
                color: AppStyles.accentColor
            )
            
            // Most played song
            if let topSong = musicLibrary.songs.sorted(by: { $0.playCount > $1.playCount }).first {
                StatCard(
                    title: "Most Played",
                    value: topSong.title ?? "Unknown",
                    subtitle: "\(topSong.playCount) plays",
                    icon: "star.fill",
                    color: .orange
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var artistVarietySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Artist Variety")
                    .font(.subheadline)
                    .foregroundColor(AppStyles.accentColor)
                
                Spacer()
                
                Text(artistVarietyDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Artist contribution visualization
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        if i < artistContribution.count {
                            Rectangle()
                                .fill(AppStyles.accentColor.opacity(1.0 - (Double(i) * 0.15)))
                                .frame(width: getPercentageWidth(for: i, in: geo.size.width))
                        }
                    }
                    
                    if let otherPercentage = otherArtistsPercentage, otherPercentage > 0 {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: geo.size.width * otherPercentage / 100.0)
                    }
                }
            }
            .frame(height: 30)
            .cornerRadius(AppStyles.cornerRadius)
            
            // Legend
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(artistContribution.prefix(5).enumerated()), id: \.element.id) { index, artist in
                    HStack {
                        Rectangle()
                            .fill(AppStyles.accentColor.opacity(1.0 - (Double(index) * 0.15)))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        
                        Text(artist.name)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(getArtistPercentage(for: artist))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let otherPercentage = otherArtistsPercentage, otherPercentage > 0 {
                    HStack {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        
                        Text("Other Artists")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(otherPercentage.rounded()))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
        .padding(.horizontal)
    }
    
    private var albumCompletionSection: some View {
        HStack(spacing: 20) {
            // Completion rate visualization
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 10)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: albumCompletionRate)
                    .stroke(AppStyles.accentColor, lineWidth: 10)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(albumCompletionRate * 100))%")
                    .font(.system(size: 18, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Album Completion")
                    .font(.subheadline)
                    .foregroundColor(AppStyles.accentColor)
                
                Text("You tend to \(albumListeningDescription) when listening to albums")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var repeatListeningScore: Double {
        let playedSongs = musicLibrary.songs.filter { $0.playCount > 0 }
        if playedSongs.isEmpty { return 0.0 }
        
        let totalPlays = playedSongs.reduce(0) { $0 + $1.playCount }
        let avgPlaysPerSong = Double(totalPlays) / Double(playedSongs.count)
        
        return min(1.0, log(avgPlaysPerSong) / log(20.0))
    }
    
    private var repeatListeningDescription: String {
        if repeatListeningScore < 0.3 {
            return "Explorer"
        } else if repeatListeningScore < 0.6 {
            return "Balanced"
        } else {
            return "Repeater"
        }
    }
    
    private var artistContribution: [ArtistData] {
        musicLibrary.artists.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private var otherArtistsPercentage: Double? {
        let totalPlays = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        let top5Plays = artistContribution.prefix(5).reduce(0) { $0 + $1.totalPlayCount }
        let otherPlays = totalPlays - top5Plays
        
        guard totalPlays > 0, otherPlays > 0 else { return nil }
        return Double(otherPlays) / Double(totalPlays) * 100.0
    }
    
    private var artistVarietyDescription: String {
        let topArtistPercentage = getArtistPercentage(for: artistContribution.first!)
        
        if topArtistPercentage < 40 {
            return "Very Diverse"
        } else if topArtistPercentage < 60 {
            return "Balanced"
        } else if topArtistPercentage < 80 {
            return "Focused"
        } else {
            return "Very Focused"
        }
    }
    
    private var albumCompletionRate: Double {
        var totalAlbumSongs = 0
        var totalPlayedAlbumSongs = 0
        
        for album in musicLibrary.albums {
            let albumSongs = album.songs.count
            let playedSongs = album.songs.filter { $0.playCount > 0 }.count
            
            totalAlbumSongs += albumSongs
            totalPlayedAlbumSongs += playedSongs
        }
        
        guard totalAlbumSongs > 0 else { return 0.0 }
        return Double(totalPlayedAlbumSongs) / Double(totalAlbumSongs)
    }
    
    private var albumListeningDescription: String {
        if albumCompletionRate < 0.3 {
            return "cherry-pick specific tracks"
        } else if albumCompletionRate < 0.7 {
            return "listen to selected songs"
        } else {
            return "listen to complete albums"
        }
    }
    
    private func getArtistPercentage(for artist: ArtistData) -> Double {
        let totalPlays = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        guard totalPlays > 0 else { return 0 }
        
        return Double(artist.totalPlayCount) / Double(totalPlays) * 100.0
    }
    
    private func getPercentageWidth(for index: Int, in totalWidth: CGFloat) -> CGFloat {
        guard index < artistContribution.count else { return 0 }
        
        let percentage = getArtistPercentage(for: artistContribution[index])
        return totalWidth * percentage / 100.0
    }
}
