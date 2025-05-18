//  GenreDetailView.swift
//  Music Memory

import SwiftUI
import MediaPlayer

struct GenreDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let genre: GenreData
    let rank: Int?
    
    init(genre: GenreData, rank: Int? = nil) {
        self.genre = genre
        self.rank = rank
    }
    
    var body: some View {
        MediaDetailView(
            item: genre,
            rank: rank,
            headerContent: { _ in headerSection },
            additionalContent: { _ in contentSections }
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        // Breaking up expressions for better type checking
        let artists = findGenreArtists()
        let albums = findGenreAlbums()
        
        // Determine what can be sorted
        let hasMultipleSongs = genre.songs.count > 1
        let hasMultipleAlbums = albums.count > 1
        let hasMultipleArtists = artists.count > 1
        
        return Group {
            if hasMultipleSongs || hasMultipleArtists || hasMultipleAlbums {
                VStack(spacing: 12) {
                    // Sort Albums Button - only show if there are multiple albums
                    if hasMultipleAlbums {
                        SortActionButton(
                            title: "Sort Albums",
                            items: albums,
                            source: .genre,
                            sourceID: genre.id,
                            sourceName: genre.name,
                            contentType: .albums,
                            artwork: genre.artwork
                        )
                    }
                    
                    // Sort Artists Button - only show if there are multiple artists
                    if hasMultipleArtists {
                        SortActionButton(
                            title: "Sort Artists",
                            items: artists,
                            source: .genre,
                            sourceID: genre.id,
                            sourceName: genre.name,
                            contentType: .artists,
                            artwork: genre.artwork
                        )
                    }
                    
                    // Sort Songs Button - only show if there are multiple songs
                    if hasMultipleSongs {
                        SortActionButton(
                            title: "Sort Songs",
                            items: genre.songs,
                            source: .genre,
                            sourceID: genre.id,
                            sourceName: genre.name,
                            contentType: .songs,
                            artwork: genre.artwork
                        )
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color(UIColor.systemGroupedBackground))
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
    }
    
    // MARK: - Content Sections
    
    private var contentSections: some View {
        Group {
            // Songs section
            SongsSection(songs: genre.songs)
            
            // Albums section
            genreAlbumsSection
            
            // Artists section
            genreArtistsSection
            
            // Playlists section - now with RankedPlaylistsSection
            genrePlaylistsSection
        }
    }
    
    // MARK: - Album Section
    
    private var genreAlbumsSection: some View {
        let albums = findGenreAlbums()
        if !albums.isEmpty {
            return AnyView(AlbumsSection(albums: albums))
        } else {
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - Artist Section
    
    private var genreArtistsSection: some View {
        let artists = findGenreArtists()
        if !artists.isEmpty {
            return AnyView(ArtistsSection(artists: artists))
        } else {
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - Playlist Section with RankedPlaylistsSection
    
    private var genrePlaylistsSection: some View {
        let containingPlaylists = findPlaylists()
        
        return Group {
            if !containingPlaylists.isEmpty {
                RankedPlaylistsSection(
                    playlists: containingPlaylists,
                    title: containingPlaylists.count == 1 ? "Playlist" : "Playlists",
                    getRankData: { playlist in
                        getGenreRankInPlaylist(genre: genre, playlist: playlist)
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findGenreArtists() -> [ArtistData] {
        // Get unique artist names in this genre
        let artistNames = Set(genre.songs.compactMap { $0.artist })
        
        // Find corresponding artist objects
        let artists = artistNames.compactMap { name -> ArtistData? in
            musicLibrary.artists.first { $0.name == name }
        }
        
        // Sort by play count
        return artists.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findGenreAlbums() -> [AlbumData] {
        // Get unique album titles in this genre
        let albumTitles = Set(genre.songs.compactMap { $0.albumTitle })
        
        // Find corresponding album objects
        let albums = albumTitles.compactMap { title -> AlbumData? in
            musicLibrary.albums.first { $0.title == title }
        }
        
        // Sort by play count
        return albums.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findPlaylists() -> [PlaylistData] {
        let genreSongIDs = Set(genre.songs.map { $0.persistentID })
        
        return musicLibrary.playlists.filter { playlist in
            // Check if playlist contains at least one song from this genre
            playlist.songs.contains { genreSongIDs.contains($0.persistentID) }
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // MARK: - Ranking Helper Method
    
    // Get genre's rank within a playlist - returns tuple format needed for RankedPlaylistsSection
    private func getGenreRankInPlaylist(genre: GenreData, playlist: PlaylistData) -> (rank: Int, total: Int)? {
        // Get all genres in this playlist
        let playlistGenreNames = Set(playlist.songs.compactMap { $0.genre }).filter { !$0.isEmpty }
        let playlistGenres = playlistGenreNames.compactMap { name -> GenreData? in
            musicLibrary.genres.first { $0.name == name }
        }
        
        // Calculate play counts per genre from this playlist's songs
        var genrePlayCounts: [String: Int] = [:]
        for playlistGenre in playlistGenres {
            let playlistSongsInGenre = playlist.songs.filter { $0.genre == playlistGenre.name }
            let totalPlays = playlistSongsInGenre.reduce(0) { $0 + $1.playCount }
            genrePlayCounts[playlistGenre.id] = totalPlays
        }
        
        // Sort genres by play count
        let sortedGenreIDs = genrePlayCounts.sorted { $0.value > $1.value }.map { $0.key }
        
        // Find this genre's position
        if let index = sortedGenreIDs.firstIndex(of: genre.id) {
            return (rank: index + 1, total: playlistGenres.count)
        }
        
        return nil
    }
}
