//
//  AlbumDetailView.swift
//  Music Memory
//
//  Created by Jacob Rees on 28/04/2025.
//

import SwiftUI
import MediaPlayer

struct AlbumDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let album: AlbumData
    let rank: Int?
    
    // Initialize with an optional rank parameter
    init(album: AlbumData, rank: Int? = nil) {
        self.album = album
        self.rank = rank
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Helper function to format time duration
    private func formatTotalDuration() -> String {
        let totalSeconds = album.songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Function to determine the most common genre in the album
    private func mostCommonGenre() -> String {
        var genreCounts: [String: Int] = [:]
        
        for song in album.songs {
            if let genre = song.genre {
                genreCounts[genre, default: 0] += 1
            }
        }
        
        return genreCounts.max(by: { $0.value < $1.value })?.key ?? "Unknown"
    }
    
    // Function to get release year of the album
    private func releaseYear() -> String {
        // Try to find a song with a release date
        if let firstSongWithDate = album.songs.first(where: { $0.releaseDate != nil }),
           let releaseDate = firstSongWithDate.releaseDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: releaseDate)
        }
        return "Unknown"
    }
    
    // Function to get date added to library
    private func dateAdded() -> Date? {
        // Find the earliest date added among all songs
        return album.songs.compactMap { $0.dateAdded }.min()
    }
    
    var body: some View {
        List {
            // Album header section with optional rank
            Section(header: VStack(alignment: .center, spacing: 4) {
                if let rank = rank {
                    Text("Rank #\(rank)")
                        .font(.headline)
                        .foregroundColor(AppStyles.accentColor)
                        .padding(.bottom, 4)
                }
                
                DetailHeaderView(
                    title: album.title,
                    subtitle: album.artist,
                    plays: album.totalPlayCount,
                    songCount: album.songs.count,
                    artwork: album.artwork,
                    isAlbum: true,
                    metadata: []
                )
            }) {
                // Empty section content for spacing
            }
            
            // Album Statistics section
            Section(header: Text("Album Statistics")
                .padding(.leading, -15)) {
                MetadataRow(icon: "calendar", title: "Released", value: releaseYear())
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "music.note.list", title: "Genre", value: mostCommonGenre())
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "clock", title: "Duration", value: formatTotalDuration())
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "plus.circle", title: "Added", value: formatDate(dateAdded()))
                    .listRowSeparator(.hidden)
                
                if let song = album.songs.first, let composer = song.composer, !composer.isEmpty {
                    MetadataRow(icon: "music.quarternote.3", title: "Composer", value: composer)
                        .listRowSeparator(.hidden)
                }
                
                // Get number of discs in album
                let discs = Set(album.songs.compactMap { $0.discNumber }).count
                if discs > 1 {
                    MetadataRow(icon: "opticaldisc", title: "Discs", value: "\(discs)")
                        .listRowSeparator(.hidden)
                }
                
                // Average play count per song
                let avgPlays = album.totalPlayCount / max(1, album.songs.count)
                MetadataRow(icon: "repeat", title: "Avg. Plays", value: "\(avgPlays) per song")
                    .listRowSeparator(.hidden)
            }
            
            // Artist section
            Section(header: Text("Artist").padding(.leading, -15)) {
                // Find the artist in the music library
                if let artist = musicLibrary.artists.first(where: { $0.name == album.artist }) {
                    NavigationLink(destination: ArtistDetailView(artist: artist)) {
                        ArtistRow(artist: artist)
                    }
                    .listRowSeparator(.hidden)
                } else {
                    // Fallback if artist is not found
                    HStack(spacing: AppStyles.smallPadding) {
                        ZStack {
                            Circle()
                                .fill(AppStyles.secondaryColor)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "music.mic")
                                .font(.system(size: 24))
                                .foregroundColor(.primary)
                        }
                        
                        Text(album.artist)
                            .font(AppStyles.bodyStyle)
                            .lineLimit(1)
                    }
                    .listRowSeparator(.hidden)
                }
            }
            
            // Songs section with ranking
            Section(header: Text("Songs").padding(.leading, -15)) {
                ForEach(Array(album.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }.enumerated()), id: \.element.persistentID) { index, song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        HStack(spacing: 10) {
                            Text("#\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppStyles.accentColor)
                                .frame(width: 30, alignment: .leading)
                            
                            SongRow(song: song)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
