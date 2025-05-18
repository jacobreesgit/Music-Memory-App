//  ArtistDetailView.swift
//  Music Memory

import SwiftUI
import MediaPlayer

struct ArtistDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let artist: ArtistData
    let rank: Int?
    
    init(artist: ArtistData, rank: Int? = nil) {
        self.artist = artist
        self.rank = rank
    }
    
    var body: some View {
        MediaDetailView(
            item: artist,
            rank: rank,
            headerContent: { artist in
                // MARK: - Sort Buttons Section - NOW ABOVE STATISTICS
                let albums = findArtistAlbums()
                let hasMultipleSongs = artist.songs.count > 1
                let hasMultipleAlbums = albums.count > 1
                
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
                    .listRowBackground(Color(UIColor.systemGroupedBackground))
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            },
            additionalContent: { artist in
                Group {
                    // Songs section - MOVED TO TOP
                    SongsSection(songs: artist.songs)
                    
                    // Albums section
                    let artistAlbums = findArtistAlbums()
                    if !artistAlbums.isEmpty {
                        AlbumsSection(albums: artistAlbums)
                    }
                    
                    // Genres section
                    let genres = findArtistGenres()
                    if !genres.isEmpty {
                        GenresSection(genres: genres)
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
    private func findArtistAlbums() -> [AlbumData] {
        return musicLibrary.albums.filter { $0.artist == artist.name }
            .sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findArtistGenres() -> [GenreData] {
        let genreNames = Set(artist.songs.compactMap { $0.genre })
        let genres = genreNames.compactMap { name -> GenreData? in
            musicLibrary.genres.first { $0.name == name }
        }
        return genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findPlaylists() -> [PlaylistData] {
        let artistSongIDs = Set(artist.songs.map { $0.persistentID })
        return musicLibrary.playlists.filter { playlist in
            playlist.songs.contains { artistSongIDs.contains($0.persistentID) }
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
}
