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
                    // Songs section - MOVED TO TOP
                    SongsSection(songs: genre.songs)
                    
                    // Albums section
                    if !findGenreAlbums().isEmpty {
                        AlbumsSection(albums: findGenreAlbums())
                    }
                    
                    // Artists section
                    if !findGenreArtists().isEmpty {
                        ArtistsSection(artists: findGenreArtists())
                    }
                    
                    // Playlists section
                    let containingPlaylists = findPlaylists()
                    if !containingPlaylists.isEmpty {
                        PlaylistsSection(playlists: containingPlaylists)
                    }
                }
            }
        )
    }
    
    // Helper methods
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
}
