//
//  ArtistDetailView.swift
//  Music Memory
//
//  Created by Jacob Rees on 28/04/2025.
//

import SwiftUI
import MediaPlayer

struct ArtistDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let artist: ArtistData
    let rank: Int?
    
    // State variables for expanded sections - sorted alphabetically
    @State private var showAllAlbums = false
    @State private var showAllGenres = false
    @State private var showAllPlaylists = false
    @State private var showAllSongs = false
    
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
    init(artist: ArtistData, rank: Int? = nil) {
        self.artist = artist
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
    
    // Helper function to get total duration of all songs
    private func totalDuration() -> String {
        let totalSeconds = artist.songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return String(format: "%dh %dm", hours, minutes)
    }
    
    // Helper function to get first and last added song dates
    private func dateRange() -> (first: Date?, last: Date?) {
        let dates = artist.songs.compactMap { $0.dateAdded }
        return (dates.min(), dates.max())
    }
    
    // Helper to calculate days between dates
    private func datesBetween(_ startDate: Date?, _ endDate: Date?) -> Int {
        guard let start = startDate, let end = endDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
    
    // Get album data for display
    private func albumData() -> [AlbumInfo] {
        // Group songs by album
        let songsByAlbum = Dictionary(grouping: artist.songs) { song in
            song.albumTitle ?? "Unknown"
        }
        
        // Convert to array of AlbumInfo
        return songsByAlbum.map { albumTitle, songs in
            let artwork = songs.first?.artwork
            let playCount = songs.reduce(0) { $0 + (($1.playCount ?? 0)) }
            
            return AlbumInfo(
                title: albumTitle,
                artwork: artwork,
                songCount: songs.count,
                playCount: playCount
            )
        }.sorted { $0.playCount > $1.playCount }
    }
    
    // Helper function to find artist genres
    private func artistGenres() -> [GenreData] {
        // Get unique genre names from this artist's songs
        let genreNames = Set(artist.songs.compactMap { $0.genre })
        
        // Find corresponding genre objects
        let genres = genreNames.compactMap { name -> GenreData? in
            musicLibrary.genres.first { $0.name == name }
        }
        
        // Sort by play count
        return genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Helper function to find playlists containing this artist's songs
    private func findPlaylists() -> [PlaylistData] {
        let artistSongIDs = Set(artist.songs.map { $0.persistentID })
        
        return musicLibrary.playlists.filter { playlist in
            // Check if playlist contains at least one song from this artist
            playlist.songs.contains { artistSongIDs.contains($0.persistentID) }
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Find all albums by this artist
    private func artistAlbums() -> [AlbumData] {
        return musicLibrary.albums.filter { $0.artist == artist.name }
    }
    
    // Simple struct to hold album info for display
    private struct AlbumInfo: Identifiable {
        var id: String { title }
        let title: String
        let artwork: MPMediaItemArtwork?
        let songCount: Int
        let playCount: Int
    }
    
    var body: some View {
        List {
            // Artist header section with optional rank
            Section(header: VStack(alignment: .center, spacing: 4) {
                DetailHeaderView(
                    title: artist.name,
                    subtitle: "",
                    plays: artist.totalPlayCount,
                    songCount: artist.songs.count,
                    artwork: artist.artwork,
                    isAlbum: false,
                    metadata: [],
                    rank: rank
                )
            }) {
                // Empty section content for spacing
            }
            
            // MARK: - Sort Buttons Section (sorted alphabetically by media type)
            let albums = artistAlbums()
            let hasMultipleSongs = artist.songs.count > 1
            let hasMultipleAlbums = albums.count > 1
            
            // Only show the sort buttons section if there are multiple items to sort
            if hasMultipleSongs || hasMultipleAlbums {
                VStack(spacing: 12) {
                    // Sort Albums Button - only show if there are multiple albums
                    if hasMultipleAlbums {
                        SortActionButton(
                            title: "Sort Albums",
                            items: albums,
                            source: .artist,
                            sourceID: artist.id,
                            sourceName: artist.name,
                            contentType: .albums,
                            artwork: artist.artwork
                        )
                    }
                    
                    // Sort Songs Button - only show if there are multiple songs
                    if hasMultipleSongs {
                        SortActionButton(
                            title: "Sort Songs",
                            items: artist.songs,
                            source: .artist,
                            sourceID: artist.id,
                            sourceName: artist.name,
                            contentType: .songs,
                            artwork: artist.artwork
                        )
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color(UIColor.systemGroupedBackground)) // Match system background
                .listRowInsets(EdgeInsets()) // Remove default insets
                .listRowSeparator(.hidden)
            }
            
            // Artist Statistics section
            Section(header: Text("Artist Statistics")
                .padding(.leading, -15)) {
                MetadataRow(icon: "square.stack", title: "Albums", value: "\(artist.albumCount)")
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "music.note.list", title: "Genres", value: artist.topGenres().joined(separator: ", "))
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "clock", title: "Total Time", value: totalDuration())
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "plus.circle", title: "First Added", value: formatDate(dateRange().first))
                    .listRowSeparator(.hidden)
                
                let topAlbums = albumData().prefix(1)
                if let topAlbum = topAlbums.first {
                    MetadataRow(icon: "star", title: "Top Album", value: topAlbum.title)
                        .listRowSeparator(.hidden)
                    MetadataRow(icon: "music.note.tv", title: "Album Plays", value: "\(topAlbum.playCount)")
                        .listRowSeparator(.hidden)
                }
                
                // Average plays per song
                MetadataRow(icon: "repeat", title: "Avg. Plays", value: "\(artist.averagePlayCount) per song")
                    .listRowSeparator(.hidden)
                
                // Most recent addition
                if let lastAdded = dateRange().last {
                    MetadataRow(icon: "calendar", title: "Last Added", value: formatDate(lastAdded))
                        .listRowSeparator(.hidden)
                }
                
                // Listening streak (if we had the data)
                MetadataRow(icon: "chart.line.uptrend.xyaxis", title: "In Collection",
                           value: "\(datesBetween(dateRange().first, dateRange().last)) days")
                    .listRowSeparator(.hidden)
            }
            
            // Albums section with ranking and Show More/Less
            Section(header: Text("Albums").padding(.leading, -15)) {
                let albumInfoList = albumData()
                let displayedAlbums = showAllAlbums ? albumInfoList : Array(albumInfoList.prefix(5))
                
                ForEach(Array(displayedAlbums.enumerated()), id: \.element.id) { index, album in
                    if let foundAlbum = musicLibrary.albums.first(where: { $0.title == album.title && $0.artist == artist.name }) {
                        NavigationLink(destination: AlbumDetailView(album: foundAlbum)) {
                            HStack(spacing: 10) {
                                // Only show rank number if there's more than one album
                                if displayedAlbums.count > 1 {
                                    Text("#\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppStyles.accentColor)
                                        .frame(width: 30, alignment: .leading)
                                }
                                
                                albumRow(album: album)
                            }
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        HStack(spacing: 10) {
                            // Only show rank number if there's more than one album
                            if displayedAlbums.count > 1 {
                                Text("#\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 30, alignment: .leading)
                            }
                            
                            albumRow(album: album)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                
                // Show More/Less button for albums
                if albumInfoList.count > 5 {
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
            
            // Genres section with Show More/Less
            let genres = artistGenres()
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
                    
                    ForEach(Array(displayedPlaylists.enumerated()), id: \.element.id) { index, playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                            HStack(spacing: 10) {
                                // Only show rank number if there's more than one playlist
                                if displayedPlaylists.count > 1 {
                                    Text("#\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppStyles.accentColor)
                                        .frame(width: 30, alignment: .leading)
                                }
                                
                                PlaylistRow(playlist: playlist)
                            }
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
                let sortedSongs = artist.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }
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
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Row for an album in the albums list
    private func albumRow(album: AlbumInfo) -> some View {
        HStack {
            if let artwork = album.artwork {
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
            
            VStack(alignment: .leading) {
                Text(album.title)
                    .font(AppStyles.bodyStyle)
                
                Text("\(album.songCount) songs")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(album.playCount) plays")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
    }
}

// Helper view to initiate sort session
struct SortActionView<T>: View {
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let title: String
    let items: [T]
    let source: SortSession.SortSource
    let sourceID: String
    let sourceName: String
    let contentType: SortSession.ContentType
    let artwork: MPMediaItemArtwork?
    
    @State private var navigatingSortSession: SortSession?
    
    var body: some View {
        VStack {
            Text("Start sorting your \(contentTypeString) from \(sourceName)?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Start Sorting") {
                createSortSession()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            if let session = navigatingSortSession {
                NavigationLink(
                    destination: SortSessionView(session: session),
                    isActive: .constant(true),
                    label: { EmptyView() }
                )
                .hidden()
            }
        }
        .navigationTitle(title)
    }
    
    private var contentTypeString: String {
        switch contentType {
        case .songs: return "songs"
        case .albums: return "albums"
        case .artists: return "artists"
        case .genres: return "genres"
        case .playlists: return "playlists"
        }
    }
    
    // Create a sort session based on the content type
    private func createSortSession() {
        switch contentType {
        case .songs:
            if let songs = items as? [MPMediaItem] {
                let session = SortSession(
                    title: title,
                    songs: songs,
                    source: source,
                    sourceID: sourceID,
                    sourceName: sourceName,
                    artwork: artwork
                )
                sortSessionStore.addSession(session)
                navigatingSortSession = session
            }
            
        case .albums:
            if let albums = items as? [AlbumData] {
                let session = SortSession(
                    title: title,
                    albums: albums,
                    source: source,
                    sourceID: sourceID,
                    sourceName: sourceName,
                    artwork: artwork
                )
                sortSessionStore.addSession(session)
                navigatingSortSession = session
            }
            
        case .artists:
            if let artists = items as? [ArtistData] {
                let session = SortSession(
                    title: title,
                    artists: artists,
                    source: source,
                    sourceID: sourceID,
                    sourceName: sourceName,
                    artwork: artwork
                )
                sortSessionStore.addSession(session)
                navigatingSortSession = session
            }
            
        case .genres:
            if let genres = items as? [GenreData] {
                let session = SortSession(
                    title: title,
                    genres: genres,
                    source: source,
                    sourceID: sourceID,
                    sourceName: sourceName,
                    artwork: artwork
                )
                sortSessionStore.addSession(session)
                navigatingSortSession = session
            }
            
        case .playlists:
            if let playlists = items as? [PlaylistData] {
                let session = SortSession(
                    title: title,
                    playlists: playlists,
                    source: source,
                    sourceID: sourceID,
                    sourceName: sourceName,
                    artwork: artwork
                )
                sortSessionStore.addSession(session)
                navigatingSortSession = session
            }
        }
    }
}
