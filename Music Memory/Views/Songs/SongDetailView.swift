//
//  SongDetailView.swift
//  Music Memory
//
//  Created by Jacob Rees on 28/04/2025.
//

import SwiftUI
import MediaPlayer

struct SongDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let song: MPMediaItem
    let rank: Int?
    
    // State variables for expanded sections
    @State private var showAllPlaylists = false
    @State private var showAllRelatedSongs = false
    
    // Initialize with an optional rank parameter
    init(song: MPMediaItem, rank: Int? = nil) {
        self.song = song
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
    private func formatDuration(_ timeInSeconds: TimeInterval) -> String {
        let minutes = Int(timeInSeconds / 60)
        let seconds = Int(timeInSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Helper function to find playlists containing this song
    private func findPlaylists() -> [PlaylistData] {
        return musicLibrary.playlists.filter { playlist in
            playlist.songs.contains { $0.persistentID == song.persistentID }
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Helper function to find related songs (same artist or album)
    private func findRelatedSongs() -> [MPMediaItem] {
        // Exclude the current song
        return musicLibrary.songs.filter { relatedSong in
            relatedSong.persistentID != song.persistentID && (
                relatedSong.artist == song.artist ||
                relatedSong.albumTitle == song.albumTitle
            )
        }.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }
    }
    
    // Helper function to find genre for this song
    private func findGenre() -> GenreData? {
        guard let genreName = song.genre else { return nil }
        return musicLibrary.genres.first { $0.name == genreName }
    }
    
    var body: some View {
        List {
            // Song header section with optional rank
            Section(header: VStack(alignment: .center, spacing: 4) {
                if let rank = rank {
                    Text("Rank #\(rank)")
                        .font(.headline)
                        .foregroundColor(AppStyles.accentColor)
                        .padding(.bottom, 4)
                }
                
                DetailHeaderView(
                    title: song.title ?? "Unknown",
                    subtitle: song.artist ?? "Unknown",
                    plays: song.playCount ?? 0,
                    songCount: 1,
                    artwork: song.artwork,
                    isAlbum: false,
                    metadata: []
                )
            }) {
                // Empty section content
            }
            
            // Song Statistics section
            Section(header: Text("Song Statistics")
                .padding(.leading, -15)) {
                MetadataRow(icon: "music.note.list", title: "Genre", value: song.genre ?? "Unknown")
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "clock", title: "Duration", value: formatDuration(song.playbackDuration))
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "calendar", title: "Release Date", value: formatDate(song.releaseDate))
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "play.circle", title: "Last Played", value: formatDate(song.lastPlayedDate))
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "plus.circle", title: "Date Added", value: formatDate(song.dateAdded))
                    .listRowSeparator(.hidden)
                
                if let composer = song.composer, !composer.isEmpty {
                    MetadataRow(icon: "music.quarternote.3", title: "Composer", value: composer)
                        .listRowSeparator(.hidden)
                }
                
                let trackNumber = song.albumTrackNumber
                if trackNumber > 0 {
                    MetadataRow(icon: "number", title: "Track", value: "\(trackNumber)")
                        .listRowSeparator(.hidden)
                }
                
                let discNumber = song.discNumber
                if discNumber > 0 {
                    MetadataRow(icon: "opticaldisc", title: "Disc", value: "\(discNumber)")
                        .listRowSeparator(.hidden)
                }
                
                let bpm = song.beatsPerMinute
                if bpm > 0 {
                    MetadataRow(icon: "metronome", title: "BPM", value: "\(bpm)")
                        .listRowSeparator(.hidden)
                }
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
                        .listRowSeparator(.hidden)
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
                        .listRowSeparator(.hidden)
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
                            
                            Text(artistName)
                                .font(AppStyles.bodyStyle)
                                .lineLimit(1)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            
            // Genre section
            if let genre = findGenre() {
                Section(header: Text("Genre").padding(.leading, -15)) {
                    NavigationLink(destination: GenreDetailView(genre: genre)) {
                        GenreRow(genre: genre)
                    }
                    .listRowSeparator(.hidden)
                }
            }
            
            // Related songs section with Show More/Less
            let relatedSongs = findRelatedSongs()
            if !relatedSongs.isEmpty {
                Section(header: Text("Related Songs").padding(.leading, -15)) {
                    let displayedSongs = showAllRelatedSongs ? relatedSongs : Array(relatedSongs.prefix(5))
                    
                    ForEach(Array(displayedSongs.enumerated()), id: \.element.persistentID) { index, relatedSong in
                        NavigationLink(destination: SongDetailView(song: relatedSong)) {
                            SongRow(song: relatedSong)
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    // Show More/Less button for related songs
                    if relatedSongs.count > 5 {
                        Button(action: {
                            showAllRelatedSongs.toggle()
                        }) {
                            HStack {
                                Text(showAllRelatedSongs ? "Show Less" : "Show More")
                                    .font(.subheadline)
                                    .foregroundColor(AppStyles.accentColor)
                                
                                Image(systemName: showAllRelatedSongs ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(AppStyles.accentColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowSeparator(.hidden)
                    }
                }
            }
            
            // Playlists section with Show More/Less
            let containingPlaylists = findPlaylists()
            if !containingPlaylists.isEmpty {
                Section(header: Text("In Playlists").padding(.leading, -15)) {
                    let displayedPlaylists = showAllPlaylists ? containingPlaylists : Array(containingPlaylists.prefix(5))
                    
                    ForEach(displayedPlaylists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                            PlaylistRow(playlist: playlist)
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    // Show More/Less button for playlists
                    if containingPlaylists.count > 5 {
                        Button(action: {
                            showAllPlaylists.toggle()
                        }) {
                            HStack {
                                Text(showAllPlaylists ? "Show Less" : "Show More")
                                    .font(.subheadline)
                                    .foregroundColor(AppStyles.accentColor)
                                
                                Image(systemName: showAllPlaylists ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(AppStyles.accentColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .navigationTitle(song.title ?? "Unknown")
        .navigationBarTitleDisplayMode(.inline)
    }
}
