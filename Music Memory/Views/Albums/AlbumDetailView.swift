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
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let album: AlbumData
    let rank: Int?
    
    // State variables for expanded sections
    @State private var showAllSongs = false
    @State private var showAllPlaylists = false
    @State private var showAllGenres = false
    
    // State for sorting navigation
    @State private var isNavigatingToSortSession = false
    @State private var navigatingSortSession = SortSession(
        title: "",
        songs: [],
        source: .album,
        sourceID: "",
        sourceName: ""
    )
    
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
    
    // Helper function to find all genres in this album
    private func albumGenres() -> [GenreData] {
        // Get unique genre names in this album
        let genreNames = Set(album.songs.compactMap { $0.genre })
        
        // Find corresponding genre objects from the music library
        let genres = genreNames.compactMap { name -> GenreData? in
            musicLibrary.genres.first { $0.name == name }
        }
        
        // Sort by play count
        return genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Helper function to find playlists containing songs from this album
    private func findPlaylists() -> [PlaylistData] {
        let albumSongIDs = Set(album.songs.map { $0.persistentID })
        
        return musicLibrary.playlists.filter { playlist in
            // Check if playlist contains at least one song from this album
            playlist.songs.contains { albumSongIDs.contains($0.persistentID) }
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Create a sort session from album songs
    private func createSortSession() {
        // Create a new sort session from this album's songs
        navigatingSortSession = SortSession(
            title: "Sort: \(album.title)",
            songs: album.songs,
            source: .album,
            sourceID: album.id,
            sourceName: album.title,
            artwork: album.artwork
        )
        
        // Add to session store
        sortSessionStore.addSession(navigatingSortSession)
        
        // Navigate to sorting interface
        isNavigatingToSortSession = true
    }
    
    var body: some View {
        List {
            // Album header section with optional rank
            Section(header: VStack(alignment: .center, spacing: 4) {
                DetailHeaderView(
                    title: album.title,
                    subtitle: album.artist,
                    plays: album.totalPlayCount,
                    songCount: album.songs.count,
                    artwork: album.artwork,
                    isAlbum: true,
                    metadata: [],
                    rank: rank
                )
            }) {
                // Empty section content for spacing
            }
            
            // MARK: - Sort Songs Button
            if album.songs.count > 1 {
                Button(action: {
                    createSortSession()
                }) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 18))
                        
                        Text("Sort Songs")
                            .font(.headline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(AppStyles.accentColor.gradient)
                    .cornerRadius(AppStyles.cornerRadius)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 0)
                .background(
                    NavigationLink(
                        destination: SortSessionView(session: navigatingSortSession),
                        isActive: $isNavigatingToSortSession,
                        label: { EmptyView() }
                    )
                    .opacity(0)
                )
                .listRowBackground(Color(UIColor.systemGroupedBackground)) // Match the system background
                .listRowInsets(EdgeInsets()) // Remove default insets
                .listRowSeparator(.hidden)
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
            
            // Genres section with Show More/Less
            let genres = albumGenres()
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
            
            // Songs section with ranking and Show More/Less
            Section(header: Text("Songs").padding(.leading, -15)) {
                let sortedSongs = album.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }
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
        .listSectionSpacing(0)
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
