//
//  PlaylistDetailView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//

import SwiftUI
import MediaPlayer

struct PlaylistDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let playlist: PlaylistData
    let rank: Int?
    
    // State variables for expanded sections - sorted alphabetically
    @State private var showAllAlbums = false
    @State private var showAllArtists = false
    @State private var showAllGenres = false
    @State private var showAllSongs = false
    
    // State for sorting navigation
    @State private var isNavigatingToSortSession = false
    @State private var navigatingSortSession = SortSession(
        title: "",
        songs: [],
        source: .playlist,
        sourceID: "",
        sourceName: ""
    )
    
    // Initialize with an optional rank parameter
    init(playlist: PlaylistData, rank: Int? = nil) {
        self.playlist = playlist
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
    
    // Helper function to format total duration
    private func totalDuration() -> String {
        let totalSeconds = playlist.songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Helper function to get first and last added song dates
    private func dateRange() -> (first: Date?, last: Date?) {
        let dates = playlist.songs.compactMap { $0.dateAdded }
        return (dates.min(), dates.max())
    }
    
    // Find albums contained in this playlist
    private func playlistAlbums() -> [AlbumData] {
        // Get unique album titles in this playlist
        let albumTitles = Set(playlist.songs.compactMap { $0.albumTitle })
        
        // Find corresponding album objects from the music library
        let albums = albumTitles.compactMap { title -> AlbumData? in
            musicLibrary.albums.first { $0.title == title }
        }
        
        // Sort by play count
        return albums.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Find genres contained in this playlist
    private func playlistGenres() -> [GenreData] {
        // Get unique genre names in this playlist
        let genreNames = Set(playlist.songs.compactMap { $0.genre })
        
        // Find corresponding genre objects from the music library
        let genres = genreNames.compactMap { name -> GenreData? in
            musicLibrary.genres.first { $0.name == name }
        }
        
        // Sort by play count
        return genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Find top artists in playlist
    private func playlistArtists() -> [ArtistData] {
        let artistNames = Set(playlist.songs.compactMap { $0.artist })
        
        let artists = artistNames.compactMap { name -> ArtistData? in
            musicLibrary.artists.first { $0.name == name }
        }
        
        return artists.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Create a sort session from playlist songs
    private func createSortSession() {
        // Create a new sort session from this playlist's songs
        navigatingSortSession = SortSession(
            title: "Sort: \(playlist.name)",
            songs: playlist.songs,
            source: .playlist,
            sourceID: playlist.id,
            sourceName: playlist.name,
            artwork: playlist.artwork
        )
        
        // Add to session store
        sortSessionStore.addSession(navigatingSortSession)
        
        // Navigate to sorting interface
        isNavigatingToSortSession = true
    }
    
    var body: some View {
        List {
            // Playlist header section with optional rank
            Section(header: VStack(alignment: .center, spacing: 4) {
                DetailHeaderView(
                    title: playlist.name,
                    subtitle: "",
                    plays: playlist.totalPlayCount,
                    songCount: playlist.songs.count,
                    artwork: playlist.artwork,
                    isAlbum: false,
                    metadata: [],
                    rank: rank
                )
            }) {
                // Empty section content for spacing
            }
            
            // MARK: - Sort Buttons Section (sorted alphabetically by media type)
            let artists = playlistArtists()
            let albums = playlistAlbums()
            let genres = playlistGenres()
            
            // Determine what can be sorted
            let hasMultipleSongs = playlist.songs.count > 1
            let hasMultipleAlbums = albums.count > 1
            let hasMultipleArtists = artists.count > 1
            let hasMultipleGenres = genres.count > 1
            
            if hasMultipleSongs || hasMultipleArtists || hasMultipleAlbums || hasMultipleGenres {
                VStack(spacing: 12) {
                    // Sort Albums Button - only show if there are multiple albums
                    if hasMultipleAlbums {
                        SortActionButton(
                            title: "Sort Albums",
                            items: albums,
                            source: .playlist,
                            sourceID: playlist.id,
                            sourceName: playlist.name,
                            contentType: .albums,
                            artwork: playlist.artwork
                        )
                    }
                    
                    // Sort Artists Button - only show if there are multiple artists
                    if hasMultipleArtists {
                        SortActionButton(
                            title: "Sort Artists",
                            items: artists,
                            source: .playlist,
                            sourceID: playlist.id,
                            sourceName: playlist.name,
                            contentType: .artists,
                            artwork: playlist.artwork
                        )
                    }
                    
                    // Sort Genres Button - only show if there are multiple genres
                    if hasMultipleGenres {
                        SortActionButton(
                            title: "Sort Genres",
                            items: genres,
                            source: .playlist,
                            sourceID: playlist.id,
                            sourceName: playlist.name,
                            contentType: .genres,
                            artwork: playlist.artwork
                        )
                    }
                    
                    // Sort Songs Button - only show if there are multiple songs
                    if hasMultipleSongs {
                        SortActionButton(
                            title: "Sort Songs",
                            items: playlist.songs,
                            source: .playlist,
                            sourceID: playlist.id,
                            sourceName: playlist.name,
                            contentType: .songs,
                            artwork: playlist.artwork
                        )
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color(UIColor.systemGroupedBackground)) // Match system background
                .listRowInsets(EdgeInsets()) // Remove default insets
                .listRowSeparator(.hidden)
            }
            
            // Playlist Statistics section
            Section(header: Text("Playlist Statistics")
                .padding(.leading, -15)) {
                MetadataRow(icon: "square.stack", title: "Albums", value: "\(playlist.albumCount)")
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "music.note.list", title: "Top Genres", value: playlist.topGenres().joined(separator: ", "))
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "clock", title: "Total Time", value: totalDuration())
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "plus.circle", title: "First Added", value: formatDate(dateRange().first))
                    .listRowSeparator(.hidden)
                
                // Most recent addition
                if let lastAdded = dateRange().last {
                    MetadataRow(icon: "calendar", title: "Last Added", value: formatDate(lastAdded))
                        .listRowSeparator(.hidden)
                }
                
                // Average plays per song
                MetadataRow(icon: "repeat", title: "Avg. Plays", value: "\(playlist.averagePlayCount) per song")
                    .listRowSeparator(.hidden)
            }
            
            // Albums section with Show More/Less
            if !albums.isEmpty {
                Section(header: Text("Albums").padding(.leading, -15)) {
                    let displayedAlbums = showAllAlbums ? albums : Array(albums.prefix(5))
                    
                    ForEach(Array(displayedAlbums.enumerated()), id: \.element.id) { index, album in
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            HStack(spacing: 10) {
                                // Only show rank number if there's more than one album
                                if displayedAlbums.count > 1 {
                                    Text("#\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppStyles.accentColor)
                                        .frame(width: 30, alignment: .leading)
                                }
                                
                                AlbumRow(album: album)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    // Show More/Less button for albums
                    if albums.count > 5 {
                        Button(action: {
                            showAllAlbums.toggle()
                        }) {
                            HStack {
                                Text(showAllAlbums ? "Show Less" : "Show More")
                                    .font(.subheadline)
                                    .foregroundColor(AppStyles.accentColor)
                                
                                Image(systemName: showAllAlbums ? "chevron.up" : "chevron.down")
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
            
            // Artists section with Show More/Less
            Section(header: Text("Artists").padding(.leading, -15)) {
                let displayedArtists = showAllArtists ? artists : Array(artists.prefix(5))
                
                ForEach(Array(displayedArtists.enumerated()), id: \.element.id) { index, artist in
                    NavigationLink(destination: ArtistDetailView(artist: artist)) {
                        HStack(spacing: 10) {
                            // Only show rank number if there's more than one artist
                            if displayedArtists.count > 1 {
                                Text("#\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 30, alignment: .leading)
                            }
                            
                            ArtistRow(artist: artist)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                
                // Show More/Less button for artists
                if artists.count > 5 {
                    Button(action: {
                        showAllArtists.toggle()
                    }) {
                        HStack {
                            Text(showAllArtists ? "Show Less" : "Show More")
                                .font(.subheadline)
                                .foregroundColor(AppStyles.accentColor)
                            
                            Image(systemName: showAllArtists ? "chevron.up" : "chevron.down")
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
            
            // Genres section with Show More/Less
            if !genres.isEmpty {
                Section(header: Text("Genres").padding(.leading, -15)) {
                    let displayedGenres = showAllGenres ? genres : Array(genres.prefix(5))
                    
                    ForEach(Array(displayedGenres.enumerated()), id: \.element.id) { index, genre in
                        NavigationLink(destination: GenreDetailView(genre: genre)) {
                            HStack(spacing: 10) {
                                // Only show rank number if there's more than one genre
                                if displayedGenres.count > 1 {
                                    Text("#\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppStyles.accentColor)
                                        .frame(width: 30, alignment: .leading)
                                }
                                
                                GenreRow(genre: genre)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    // Show More/Less button for genres
                    if genres.count > 5 {
                        Button(action: {
                            showAllGenres.toggle()
                        }) {
                            HStack {
                                Text(showAllGenres ? "Show Less" : "Show More")
                                    .font(.subheadline)
                                    .foregroundColor(AppStyles.accentColor)
                                
                                Image(systemName: showAllGenres ? "chevron.up" : "chevron.down")
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
            
            // Songs section with ranking and Show More/Less
            Section(header: Text("Songs").padding(.leading, -15)) {
                let sortedSongs = playlist.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }
                let displayedSongs = showAllSongs ? sortedSongs : Array(sortedSongs.prefix(5))
                
                ForEach(Array(displayedSongs.enumerated()), id: \.element.persistentID) { index, song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        HStack(spacing: 10) {
                            // Only show rank number if there's more than one song
                            if displayedSongs.count > 1 {
                                Text("#\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 30, alignment: .leading)
                            }
                            
                            SongRow(song: song)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                
                // Show More/Less button for songs
                if sortedSongs.count > 5 {
                    Button(action: {
                        showAllSongs.toggle()
                    }) {
                        HStack {
                            Text(showAllSongs ? "Show Less" : "Show More")
                                .font(.subheadline)
                                .foregroundColor(AppStyles.accentColor)
                            
                            Image(systemName: showAllSongs ? "chevron.up" : "chevron.down")
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
        .listSectionSpacing(0) // Custom section spacing to reduce space between sections
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
