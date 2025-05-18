//  AlbumDetailView.swift
//  Music Memory

import SwiftUI
import MediaPlayer

struct AlbumDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let album: AlbumData
    let rank: Int?
    
    init(album: AlbumData, rank: Int? = nil) {
        self.album = album
        self.rank = rank
    }
    
    var body: some View {
        MediaDetailView(
            item: album,
            rank: rank,
            headerContent: { album in
                // MARK: - Sort Songs Button - NOW ABOVE STATISTICS
                if album.songs.count > 1 {
                    SortActionButton(
                        title: "Sort Songs",
                        items: album.songs,
                        source: .album,
                        sourceID: album.id,
                        sourceName: album.title,
                        contentType: .songs,
                        artwork: album.artwork
                    )
                    .padding(.vertical, 8)
                    .listRowBackground(Color(UIColor.systemGroupedBackground))
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            },
            additionalContent: { album in
                Group {
                    // Artist section
                    if let artist = findArtist(for: album) {
                        Section(header: Text("Artist").padding(.leading, -15)) {
                            NavigationLink(destination: ArtistDetailView(artist: artist)) {
                                LibraryRow.artist(artist)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    
                    // Genres section
                    let genres = findGenres(for: album)
                    if !genres.isEmpty {
                        GenresSection(genres: genres)
                    }
                    
                    // Playlists section
                    let containingPlaylists = findPlaylists(for: album)
                    if !containingPlaylists.isEmpty {
                        PlaylistsSection(playlists: containingPlaylists)
                    }
                    
                    // Songs section
                    SongsSection(songs: album.songs)
                }
            }
        )
    }
    
    // Helper methods
    private func findArtist(for album: AlbumData) -> ArtistData? {
        return musicLibrary.artists.first { $0.name == album.artist }
    }
    
    private func findGenres(for album: AlbumData) -> [GenreData] {
        let genreNames = Set(album.songs.compactMap { $0.genre })
        let genres = genreNames.compactMap { name -> GenreData? in
            musicLibrary.genres.first { $0.name == name }
        }
        return genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findPlaylists(for album: AlbumData) -> [PlaylistData] {
        let albumSongIDs = Set(album.songs.map { $0.persistentID })
        return musicLibrary.playlists.filter { playlist in
            playlist.songs.contains { albumSongIDs.contains($0.persistentID) }
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
}
