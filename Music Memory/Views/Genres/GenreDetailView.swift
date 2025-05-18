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
            headerContent: { genre in
                // MARK: - Sort Buttons Section - NOW ABOVE STATISTICS
                let artists = findGenreArtists()
                let albums = findGenreAlbums()
                
                // Determine what can be sorted
                let hasMultipleSongs = genre.songs.count > 1
                let hasMultipleAlbums = albums.count > 1
                let hasMultipleArtists = artists.count > 1
                
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
            },
            additionalContent: { genre in
                Group {
                    // Songs section - MOVED TO TOP - internal rankings already provided
                    SongsSection(songs: genre.songs)
                    
                    // Albums section - internal rankings already provided
                    if !findGenreAlbums().isEmpty {
                        AlbumsSection(albums: findGenreAlbums())
                    }
                    
                    // Artists section - internal rankings already provided
                    if !findGenreArtists().isEmpty {
                        ArtistsSection(artists: findGenreArtists())
                    }
                    
                    // Playlists section - now with contextual external rankings
                    let containingPlaylists = findPlaylists()
                    if !containingPlaylists.isEmpty {
                        Section(header: Text("In Playlists").padding(.leading, -15)) {
                            ForEach(containingPlaylists) { playlist in
                                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                    HStack(spacing: 10) {
                                        // Show genre's rank within this playlist
                                        if let genreRankData = getGenreRankInPlaylist(genre: genre, playlist: playlist) {
                                            Text("\(genreRankData.rank)/\(genreRankData.total)")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppStyles.accentColor)
                                                .frame(width: 50, alignment: .leading)
                                        }
                                        
                                        LibraryRow.playlist(playlist)
                                    }
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
            }
        )
    }
    
    // Existing helper methods
    private func findGenreArtists() -> [ArtistData] {
        // Get unique artist names in this genre
        let artistNames = Set(genre.songs.compactMap { $0.artist })
        
        // Find corresponding artist objects from the music library
        let artists = artistNames.compactMap { name -> ArtistData? in
            musicLibrary.artists.first { $0.name == name }
        }
        
        // Sort by play count
        return artists.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findGenreAlbums() -> [AlbumData] {
        // Get unique album titles in this genre
        let albumTitles = Set(genre.songs.compactMap { $0.albumTitle })
        
        // Find corresponding album objects from the music library
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
    
    // MARK: - New Helper Methods for Contextual Rankings
    
    // Structure to hold ranking data
    private struct RankData {
        let rank: Int
        let total: Int
    }
    
    // Get genre's rank within a playlist
    private func getGenreRankInPlaylist(genre: GenreData, playlist: PlaylistData) -> RankData? {
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
            return RankData(rank: index + 1, total: playlistGenres.count)
        }
        
        return nil
    }
}
