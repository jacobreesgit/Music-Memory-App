//
//  SongsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI
import MediaPlayer

struct SongsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        NavigationView {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading songs...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                List {
                    ForEach(musicLibrary.songs, id: \.persistentID) { song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            SongRow(song: song)
                        }
                    }
                }
                .navigationTitle("Songs by Plays")
            }
        }
    }
}

struct SongDetailView: View {
    let song: MPMediaItem
    
    // Helper function to format date
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Helper function to format time duration
    private func formatDuration(_ timeInSeconds: TimeInterval) -> String {
        let minutes = Int(timeInSeconds / 60)
        let seconds = Int(timeInSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        List {
            Section(header: DetailHeaderView(
                title: song.title ?? "Unknown",
                subtitle: song.artist ?? "Unknown",
                plays: song.playCount ?? 0,
                songCount: 1,
                artwork: song.artwork,
                isAlbum: false,
                metadata: [
                    MetadataItem(
                        iconName: "square.stack",
                        label: "Album:",
                        value: song.albumTitle ?? "Unknown"
                    ),
                    MetadataItem(
                        iconName: "music.note.list",
                        label: "Genre:",
                        value: song.genre ?? "Unknown"
                    ),
                    MetadataItem(
                        iconName: "clock",
                        label: "Duration:",
                        value: formatDuration(song.playbackDuration)
                    ),
                    MetadataItem(
                        iconName: "calendar",
                        label: "Release Date:",
                        value: formatDate(song.releaseDate)
                    ),
                    MetadataItem(
                        iconName: "play.circle",
                        label: "Last Played:",
                        value: formatDate(song.lastPlayedDate)
                    ),
                    MetadataItem(
                        iconName: "plus.circle",
                        label: "Date Added:",
                        value: formatDate(song.dateAdded)
                    )
                ]
            )) {
                // Song details section
                VStack(alignment: .leading, spacing: 12) {
                    if let composer = song.composer, !composer.isEmpty {
                        metadataRow(icon: "music.quarternote.3", title: "Composer", value: composer)
                    }
                    
                    if let trackNumber = song.albumTrackNumber, trackNumber > 0 {
                        metadataRow(icon: "number", title: "Track", value: "\(trackNumber)")
                    }
                    
                    if let discNumber = song.discNumber, discNumber > 0 {
                        metadataRow(icon: "opticaldisc", title: "Disc", value: "\(discNumber)")
                    }
                    
                    if let bpm = song.beatsPerMinute, bpm > 0 {
                        metadataRow(icon: "metronome", title: "BPM", value: "\(bpm)")
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(song.title ?? "Unknown")
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
