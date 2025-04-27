//
//  AlbumsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI
import MediaPlayer

struct AlbumsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        NavigationView {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading albums...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                List(musicLibrary.albums) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        AlbumRow(album: album)
                    }
                }
                .navigationTitle("Albums by Plays")
            }
        }
    }
}

struct AlbumDetailView: View {
    let album: AlbumData
    
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
            Section(header: DetailHeaderView(
                title: album.title,
                subtitle: album.artist,
                plays: album.totalPlayCount,
                songCount: album.songs.count,
                artwork: album.artwork,
                isAlbum: true,
                metadata: []
            )) {
                ForEach(album.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }, id: \.persistentID) { song in
                    SongRow(song: song)
                }
            }
            
            // Additional album statistics section
            Section(header: Text("Album Statistics")) {
                metadataRow(icon: "calendar", title: "Released", value: releaseYear())
                metadataRow(icon: "music.note.list", title: "Genre", value: mostCommonGenre())
                metadataRow(icon: "clock", title: "Duration", value: formatTotalDuration())
                metadataRow(icon: "plus.circle", title: "Added", value: formatDate(dateAdded()))
                
                if let song = album.songs.first, let albumArtist = song.albumArtist {
                    metadataRow(icon: "person", title: "Album Artist", value: albumArtist)
                }
                
                if let song = album.songs.first, let composer = song.composer, !composer.isEmpty {
                    metadataRow(icon: "music.quarternote.3", title: "Composer", value: composer)
                }
                
                // Get number of discs in album
                let discs = Set(album.songs.compactMap { $0.discNumber }).count
                if discs > 1 {
                    metadataRow(icon: "opticaldisc", title: "Discs", value: "\(discs)")
                }
                
                // Average play count per song
                let avgPlays = album.totalPlayCount / max(1, album.songs.count)
                metadataRow(icon: "repeat", title: "Avg. Plays", value: "\(avgPlays) per song")
            }
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func metadataRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.secondary)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
