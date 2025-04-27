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
                metadata: []
            )) {
                // Empty section content to match album/artist view structure
            }
            
            // Song Statistics section as a separate top-level section
            Section(header: Text("Song Statistics")
                .padding(.leading, -15)) {
                metadataRow(icon: "square.stack", title: "Album", value: song.albumTitle ?? "Unknown")
                metadataRow(icon: "music.note.list", title: "Genre", value: song.genre ?? "Unknown")
                metadataRow(icon: "clock", title: "Duration", value: formatDuration(song.playbackDuration))
                metadataRow(icon: "calendar", title: "Release Date", value: formatDate(song.releaseDate))
                metadataRow(icon: "play.circle", title: "Last Played", value: formatDate(song.lastPlayedDate))
                metadataRow(icon: "plus.circle", title: "Date Added", value: formatDate(song.dateAdded))
                
                if let composer = song.composer, !composer.isEmpty {
                    metadataRow(icon: "music.quarternote.3", title: "Composer", value: composer)
                }
                
                let trackNumber = song.albumTrackNumber
                if trackNumber > 0 {
                    metadataRow(icon: "number", title: "Track", value: "\(trackNumber)")
                }
                
                let discNumber = song.discNumber
                if discNumber > 0 {
                    metadataRow(icon: "opticaldisc", title: "Disc", value: "\(discNumber)")
                }
                
                let bpm = song.beatsPerMinute
                if bpm > 0 {
                    metadataRow(icon: "metronome", title: "BPM", value: "\(bpm)")
                }
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
                .multilineTextAlignment(.trailing)
        }
    }
}
