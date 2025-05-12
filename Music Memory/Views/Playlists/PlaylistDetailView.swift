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
        MediaDetailView(item: playlist, rank: rank) { playlist in
            Group {
                // MARK: - Sort Buttons Section
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
                
                // Albums section
                if !albums.isEmpty {
                    AlbumsSection(albums: albums)
                }
                
                // Artists section
                ArtistsSection(artists: artists)
                
                // Genres section
                if !genres.isEmpty {
                    GenresSection(genres: genres)
                }
                
                // Songs section
                SongsSection(songs: playlist.songs)
            }
        }
    }
    
    // Helper methods
    private func findPlaylistAlbums() -> [AlbumData] {
        let albumTitles = Set(playlist.songs.compactMap { $0.albumTitle })
        let albums = albumTitles.compactMap { title -> AlbumData? in
            musicLibrary.albums.first { $0.title == title }
        }
        return albums.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findPlaylistArtists() -> [ArtistData] {
        let artistNames = Set(playlist.songs.compactMap { $0.artist })
        let artists = artistNames.compactMap { name -> ArtistData? in
            musicLibrary.artists.first { $0.name == name }
        }
        return artists.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findPlaylistGenres() -> [GenreData] {
        let genreNames = Set(playlist.songs.compactMap { $0.genre })
        let genres = genreNames.compactMap { name -> GenreData? in
            musicLibrary.genres.first { $0.name == name }
        }
        return genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
}
