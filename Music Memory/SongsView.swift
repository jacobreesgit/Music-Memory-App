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
    @EnvironmentObject var musicLibrary: MusicLibraryModel
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
            // Song header section
            Section(header: DetailHeaderView(
                title: song.title ?? "Unknown",
                subtitle: song.artist ?? "Unknown",
                plays: song.playCount ?? 0,
                songCount: 1,
                artwork: song.artwork,
                isAlbum: false,
                metadata: []
            )) {
                // Empty section content
            }
            
            // Album section
            if let albumTitle = song.albumTitle {
                Section(header: Text("Album").padding(.leading, -15)) {
                    // Find the album in the music library
                    if let album = musicLibrary.albums.first(where: {
                        $0.title == albumTitle &&
                        ($0.artist == song.artist || $0.artist == song.albumArtist)
                    }) {
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            AlbumRow(album: album)
                        }
                    } else {
                        // Fallback if album is not found
                        HStack(spacing: AppStyles.smallPadding) {
                            if let artwork = song.artwork {
                                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "square.stack")!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(AppStyles.cornerRadius)
                            } else {
                                Image(systemName: "square.stack")
                                    .frame(width: 50, height: 50)
                                    .background(AppStyles.secondaryColor)
                                    .cornerRadius(AppStyles.cornerRadius)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(albumTitle)
                                    .font(AppStyles.bodyStyle)
                                    .lineLimit(1)
                                
                                if let artist = song.artist {
                                    Text(artist)
                                        .font(AppStyles.captionStyle)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            
            // Artist section
            if let artistName = song.artist {
                Section(header: Text("Artist").padding(.leading, -15)) {
                    // Find the artist in the music library
                    if let artist = musicLibrary.artists.first(where: { $0.name == artistName }) {
                        NavigationLink(destination: ArtistDetailView(artist: artist)) {
                            ArtistRow(artist: artist)
                        }
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
                            
                            Text(artistName)
                                .font(AppStyles.bodyStyle)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            // Song Statistics section
            Section(header: Text("Song Statistics")
                .padding(.leading, -15)) {
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
