//  PlaylistDetailView.swift
//  Music Memory

import SwiftUI
import MediaPlayer

struct PlaylistDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let playlist: PlaylistData
    let rank: Int?
    
    init(playlist: PlaylistData, rank: Int? = nil) {
        self.playlist = playlist
        self.rank = rank
    }
    
    var body: some View {
        MediaDetailView(
            item: playlist,
            rank: rank,
            headerContent: { playlist in
                // MARK: - Sort Buttons Section - NOW ABOVE STATISTICS
                let artists = findPlaylistArtists()
                let albums = findPlaylistAlbums()
                let genres = findPlaylistGenres()
                
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
                    .listRowBackground(Color(UIColor.systemGroupedBackground))
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            },
            additionalContent: { playlist in
                Group {
                    // Songs section with internal rankings - already provided by SongsSection
                    SongsSection(songs: playlist.songs)
                    
                    // Albums section - using custom PlaylistAlbumsSection to maintain "Show More" functionality
                    let albums = findPlaylistAlbums()
                    if !albums.isEmpty {
                        PlaylistAlbumsSection(albums: albums, title: "Albums")
                    }
                    
                    // Artists section - using custom PlaylistArtistsSection to maintain "Show More" functionality
                    let artists = findPlaylistArtists()
                    if !artists.isEmpty {
                        PlaylistArtistsSection(artists: artists, title: "Artists")
                    }
                    
                    // Genres section - using custom PlaylistGenresSection to maintain "Show More" functionality
                    let genres = findPlaylistGenres()
                    if !genres.isEmpty {
                        PlaylistGenresSection(genres: genres, title: "Genres")
                    }
                }
            }
        )
    }
    
    // Existing helper methods
    private func findPlaylistAlbums() -> [AlbumData] {
        // Get albums from playlist songs, sorted by play count within this playlist
        let albumTitles = Set(playlist.songs.compactMap { $0.albumTitle })
        
        // Create a dictionary to track play counts per album
        var albumPlayCounts: [String: (album: AlbumData?, playCount: Int)] = [:]
        
        // Calculate total play count per album from this playlist's songs
        for title in albumTitles {
            let album = musicLibrary.albums.first { $0.title == title }
            let playlistSongsInAlbum = playlist.songs.filter { $0.albumTitle == title }
            let totalPlays = playlistSongsInAlbum.reduce(0) { $0 + $1.playCount }
            
            albumPlayCounts[title] = (album: album, playCount: totalPlays)
        }
        
        // Extract albums and sort by their play count within this playlist
        let sortedAlbums = albumPlayCounts.compactMap { $0.value.album }
            .sorted {
                let count1 = albumPlayCounts[$0.title]?.playCount ?? 0
                let count2 = albumPlayCounts[$1.title]?.playCount ?? 0
                return count1 > count2
            }
        
        return sortedAlbums
    }
    
    private func findPlaylistArtists() -> [ArtistData] {
        // Get artists from playlist songs, sorted by play count within this playlist
        let artistNames = Set(playlist.songs.compactMap { $0.artist })
        
        // Create a dictionary to track play counts per artist
        var artistPlayCounts: [String: (artist: ArtistData?, playCount: Int)] = [:]
        
        // Calculate total play count per artist from this playlist's songs
        for name in artistNames {
            let artist = musicLibrary.artists.first { $0.name == name }
            let playlistSongsByArtist = playlist.songs.filter { $0.artist == name }
            let totalPlays = playlistSongsByArtist.reduce(0) { $0 + $1.playCount }
            
            artistPlayCounts[name] = (artist: artist, playCount: totalPlays)
        }
        
        // Extract artists and sort by their play count within this playlist
        let sortedArtists = artistPlayCounts.compactMap { $0.value.artist }
            .sorted {
                let count1 = artistPlayCounts[$0.name]?.playCount ?? 0
                let count2 = artistPlayCounts[$1.name]?.playCount ?? 0
                return count1 > count2
            }
        
        return sortedArtists
    }
    
    private func findPlaylistGenres() -> [GenreData] {
        // Get genres from playlist songs, sorted by play count within this playlist
        let genreNames = Set(playlist.songs.compactMap { $0.genre })
        
        // Create a dictionary to track play counts per genre
        var genrePlayCounts: [String: (genre: GenreData?, playCount: Int)] = [:]
        
        // Calculate total play count per genre from this playlist's songs
        for name in genreNames {
            let genre = musicLibrary.genres.first { $0.name == name }
            let playlistSongsByGenre = playlist.songs.filter { $0.genre == name }
            let totalPlays = playlistSongsByGenre.reduce(0) { $0 + $1.playCount }
            
            genrePlayCounts[name] = (genre: genre, playCount: totalPlays)
        }
        
        // Extract genres and sort by their play count within this playlist
        let sortedGenres = genrePlayCounts.compactMap { $0.value.genre }
            .sorted {
                let count1 = genrePlayCounts[$0.name]?.playCount ?? 0
                let count2 = genrePlayCounts[$1.name]?.playCount ?? 0
                return count1 > count2
            }
        
        return sortedGenres
    }
}

// MARK: - Custom Section Components with Ranking and Show More/Less Functionality

/// Custom Albums section with rank display for playlists
struct PlaylistAlbumsSection: View {
    let albums: [AlbumData]
    let title: String
    
    @State private var showAllAlbums = false
    
    init(albums: [AlbumData], title: String = "Albums") {
        self.albums = albums
        self.title = title
    }
    
    var body: some View {
        Section(header: Text(title).padding(.leading, -15)) {
            let displayedAlbums = showAllAlbums ? albums : Array(albums.prefix(5))
            
            ForEach(Array(displayedAlbums.enumerated()), id: \.element.id) { index, album in
                NavigationLink(destination: AlbumDetailView(album: album)) {
                    HStack(spacing: 10) {
                        // Show album rank with total count
                        Text("#\(index + 1)/\(albums.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .frame(width: 50, alignment: .leading)
                        
                        LibraryRow.album(album)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
            // Show More/Less button
            if albums.count > 5 {
                ExpandCollapseButton(isExpanded: $showAllAlbums)
            }
        }
    }
}

/// Custom Artists section with rank display for playlists
struct PlaylistArtistsSection: View {
    let artists: [ArtistData]
    let title: String
    
    @State private var showAllArtists = false
    
    init(artists: [ArtistData], title: String = "Artists") {
        self.artists = artists
        self.title = title
    }
    
    var body: some View {
        Section(header: Text(title).padding(.leading, -15)) {
            let displayedArtists = showAllArtists ? artists : Array(artists.prefix(5))
            
            ForEach(Array(displayedArtists.enumerated()), id: \.element.id) { index, artist in
                NavigationLink(destination: ArtistDetailView(artist: artist)) {
                    HStack(spacing: 10) {
                        // Show artist rank with total count
                        Text("#\(index + 1)/\(artists.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .frame(width: 50, alignment: .leading)
                        
                        LibraryRow.artist(artist)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
            // Show More/Less button
            if artists.count > 5 {
                ExpandCollapseButton(isExpanded: $showAllArtists)
            }
        }
    }
}

/// Custom Genres section with rank display for playlists
struct PlaylistGenresSection: View {
    let genres: [GenreData]
    let title: String
    
    @State private var showAllGenres = false
    
    init(genres: [GenreData], title: String = "Genres") {
        self.genres = genres
        self.title = title
    }
    
    var body: some View {
        Section(header: Text(title).padding(.leading, -15)) {
            let displayedGenres = showAllGenres ? genres : Array(genres.prefix(5))
            
            ForEach(Array(displayedGenres.enumerated()), id: \.element.id) { index, genre in
                NavigationLink(destination: GenreDetailView(genre: genre)) {
                    HStack(spacing: 10) {
                        // Show genre rank with total count
                        Text("#\(index + 1)/\(genres.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .frame(width: 50, alignment: .leading)
                        
                        LibraryRow.genre(genre)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
            // Show More/Less button
            if genres.count > 5 {
                ExpandCollapseButton(isExpanded: $showAllGenres)
            }
        }
    }
}
