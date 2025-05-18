// Updated SongDetailView with RankedPlaylistsSection
// Music Memory

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
                // Album section with song's rank within album
                if let albumTitle = song.albumTitle {
                    Section(header: Text("Album").padding(.leading, -15)) {
                        if let album = findAlbum(for: song) {
                            NavigationLink(destination: AlbumDetailView(album: album)) {
                                HStack(spacing: 10) {
                                    // Show song's rank within this album with total count
                                    if let rank = getSongRankInAlbum(song, album: album) {
                                        Text("#\(rank)/\(album.songs.count)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppStyles.accentColor)
                                            .frame(width: 50, alignment: .leading)
                                    }
                                    
                                    LibraryRow.album(album)
                                }
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
                
                // Artist section with song's rank within artist
                if let artistName = song.artist {
                    Section(header: Text("Artist").padding(.leading, -15)) {
                        if let artist = findArtist(for: song) {
                            NavigationLink(destination: ArtistDetailView(artist: artist)) {
                                HStack(spacing: 10) {
                                    // Show song's rank within this artist's catalog with total count
                                    if let rank = getSongRankInArtist(song, artist: artist) {
                                        Text("#\(rank)/\(artist.songs.count)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppStyles.accentColor)
                                            .frame(width: 50, alignment: .leading)
                                    }
                                    
                                    LibraryRow.artist(artist)
                                }
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
                
                // Genre section with song's rank within genre
                if let genre = findGenre(for: song) {
                    Section(header: Text("Genre").padding(.leading, -15)) {
                        NavigationLink(destination: GenreDetailView(genre: genre)) {
                            HStack(spacing: 10) {
                                // Show song's rank within this genre with total count
                                if let rank = getSongRankInGenre(song, genre: genre) {
                                    Text("#\(rank)/\(genre.songs.count)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppStyles.accentColor)
                                        .frame(width: 50, alignment: .leading)
                                }
                                
                                LibraryRow.genre(genre)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                
                // Playlists section with contextual ranking - UPDATED to use RankedPlaylistsSection
                let containingPlaylists = findPlaylists(for: song)
                if !containingPlaylists.isEmpty {
                    RankedPlaylistsSection(
                        playlists: containingPlaylists,
                        title: containingPlaylists.count == 1 ? "Playlist" : "Playlists",
                        getRankData: { playlist in
                            if let rank = getSongRankInPlaylist(song, playlist: playlist) {
                                return (rank: rank, total: playlist.songs.count)
                            }
                            return nil
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    // MARK: - Song Ranking Within Categories
    
    private func getSongRankInAlbum(_ song: MPMediaItem, album: AlbumData) -> Int? {
        // Sort album songs by play count and find this song's position
        let sortedSongs = album.songs.sorted { $0.playCount > $1.playCount }
        if let index = sortedSongs.firstIndex(where: { $0.persistentID == song.persistentID }) {
            return index + 1
        }
        return nil
    }
    
    private func getSongRankInArtist(_ song: MPMediaItem, artist: ArtistData) -> Int? {
        // Sort artist songs by play count and find this song's position
        let sortedSongs = artist.songs.sorted { $0.playCount > $1.playCount }
        if let index = sortedSongs.firstIndex(where: { $0.persistentID == song.persistentID }) {
            return index + 1
        }
        return nil
    }
    
    private func getSongRankInGenre(_ song: MPMediaItem, genre: GenreData) -> Int? {
        // Sort genre songs by play count and find this song's position
        let sortedSongs = genre.songs.sorted { $0.playCount > $1.playCount }
        if let index = sortedSongs.firstIndex(where: { $0.persistentID == song.persistentID }) {
            return index + 1
        }
        return nil
    }
    
    private func getSongRankInPlaylist(_ song: MPMediaItem, playlist: PlaylistData) -> Int? {
        // Sort playlist songs by play count and find this song's position
        let sortedSongs = playlist.songs.sorted { $0.playCount > $1.playCount }
        if let index = sortedSongs.firstIndex(where: { $0.persistentID == song.persistentID }) {
            return index + 1
        }
        return nil
    }
}
