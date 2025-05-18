//  SongDetailView.swift
//  Music Memory

import SwiftUI
import MediaPlayer

struct SongDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let song: MPMediaItem
    let rank: Int?
    
    init(song: MPMediaItem, rank: Int? = nil) {
        self.song = song
        self.rank = rank
    }
    
    var body: some View {
        MediaDetailView(item: song, rank: rank) { song in
            Group {
                // Album section
                if let albumTitle = song.albumTitle {
                    Section(header: Text("Album").padding(.leading, -15)) {
                        if let album = findAlbum(for: song) {
                            NavigationLink(destination: AlbumDetailView(album: album)) {
                                LibraryRow.album(album)
                            }
                            .listRowSeparator(.hidden)
                        } else {
                            // Fallback if album not found
                            LibraryRow(
                                title: albumTitle,
                                subtitle: song.artist ?? "Unknown",
                                playCount: 0,
                                artwork: song.artwork,
                                iconName: "square.stack"
                            )
                            .listRowSeparator(.hidden)
                        }
                    }
                }
                
                // Artist section
                if let artistName = song.artist {
                    Section(header: Text("Artist").padding(.leading, -15)) {
                        if let artist = findArtist(for: song) {
                            NavigationLink(destination: ArtistDetailView(artist: artist)) {
                                LibraryRow.artist(artist)
                            }
                            .listRowSeparator(.hidden)
                        } else {
                            // Fallback if artist not found
                            LibraryRow(
                                title: artistName,
                                subtitle: "",
                                playCount: 0,
                                artwork: nil,
                                iconName: "music.mic",
                                useCircularPlaceholder: true
                            )
                            .listRowSeparator(.hidden)
                        }
                    }
                }
                
                // Genre section
                if let genre = findGenre(for: song) {
                    Section(header: Text("Genre").padding(.leading, -15)) {
                        NavigationLink(destination: GenreDetailView(genre: genre)) {
                            LibraryRow.genre(genre)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                
                // Playlists section with dynamic title
                let containingPlaylists = findPlaylists(for: song)
                if !containingPlaylists.isEmpty {
                    let playlistTitle = containingPlaylists.count == 1 ? "Playlist" : "Playlists"
                    PlaylistsSection(playlists: containingPlaylists, title: playlistTitle)
                }
            }
        }
    }
    
    // Helper methods to find related items
    private func findAlbum(for song: MPMediaItem) -> AlbumData? {
        guard let albumTitle = song.albumTitle else { return nil }
        return musicLibrary.albums.first {
            $0.title == albumTitle &&
            ($0.artist == song.artist || $0.artist == song.albumArtist)
        }
    }
    
    private func findArtist(for song: MPMediaItem) -> ArtistData? {
        guard let artistName = song.artist else { return nil }
        return musicLibrary.artists.first { $0.name == artistName }
    }
    
    private func findGenre(for song: MPMediaItem) -> GenreData? {
        guard let genreName = song.genre else { return nil }
        return musicLibrary.genres.first { $0.name == genreName }
    }
    
    private func findPlaylists(for song: MPMediaItem) -> [PlaylistData] {
        return musicLibrary.playlists.filter { playlist in
            playlist.songs.contains { $0.persistentID == song.persistentID }
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
}
