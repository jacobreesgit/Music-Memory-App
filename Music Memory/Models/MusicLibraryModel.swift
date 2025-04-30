//
//  MusicLibraryModel.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

/// Main model for accessing and managing music library data
class MusicLibraryModel: ObservableObject {
    // MARK: - Published Properties
    @Published var songs: [MPMediaItem] = []
    @Published var albums: [AlbumData] = []
    @Published var artists: [ArtistData] = []
    @Published var genres: [GenreData] = []
    @Published var playlists: [PlaylistData] = []
    @Published var isLoading: Bool = false
    @Published var hasAccess: Bool = false
    
    // MARK: - Library Access
    
    /// Request permission and load the music library if authorized
    func requestPermissionAndLoadLibrary() {
        isLoading = true
        
        MPMediaLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if status == .authorized {
                    self.hasAccess = true
                    self.loadLibrary()
                } else {
                    self.hasAccess = false
                }
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// Load all music library data and organize into models
    func loadLibrary() {
        // Get all songs
        let songsQuery = MPMediaQuery.songs()
        if let allSongs = songsQuery.items {
            self.songs = allSongs.sorted {
                ($0.playCount ?? 0) > ($1.playCount ?? 0)
            }
        }
        
        // Process Albums
        processAlbums()
        
        // Process Artists
        processArtists()
        
        // Process Genres
        processGenres()
        
        // Process Playlists
        processPlaylists()
    }
    
    // MARK: - Private Processing Methods
    
    /// Process and group songs into albums
    private func processAlbums() {
        var albumsDict: [String: AlbumData] = [:]
        
        for song in songs {
            if let albumTitle = song.albumTitle, let artist = song.albumArtist ?? song.artist {
                let key = "\(albumTitle)-\(artist)"
                
                if var album = albumsDict[key] {
                    album.songs.append(song)
                    album.totalPlayCount += (song.playCount ?? 0)
                    albumsDict[key] = album
                } else {
                    var album = AlbumData(
                        id: key,
                        title: albumTitle,
                        artist: artist,
                        artwork: song.artwork,
                        songs: [song],
                        totalPlayCount: song.playCount ?? 0
                    )
                    albumsDict[key] = album
                }
            }
        }
        
        self.albums = Array(albumsDict.values).sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    /// Process and group songs by artists
    private func processArtists() {
        var artistsDict: [String: ArtistData] = [:]
        
        for song in songs {
            if let artist = song.artist {
                if var artistData = artistsDict[artist] {
                    artistData.songs.append(song)
                    artistData.totalPlayCount += (song.playCount ?? 0)
                    artistsDict[artist] = artistData
                } else {
                    var artistData = ArtistData(
                        name: artist,
                        songs: [song],
                        totalPlayCount: song.playCount ?? 0
                    )
                    artistsDict[artist] = artistData
                }
            }
        }
        
        self.artists = Array(artistsDict.values).sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    /// Process and group songs by genres
    private func processGenres() {
        var genresDict: [String: GenreData] = [:]
        
        for song in songs {
            if let genre = song.genre, !genre.isEmpty {
                if var genreData = genresDict[genre] {
                    genreData.songs.append(song)
                    genreData.totalPlayCount += (song.playCount ?? 0)
                    genresDict[genre] = genreData
                } else {
                    var genreData = GenreData(
                        name: genre,
                        songs: [song],
                        totalPlayCount: song.playCount ?? 0
                    )
                    genresDict[genre] = genreData
                }
            }
        }
        
        self.genres = Array(genresDict.values).sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    /// Process and load playlists
    private func processPlaylists() {
        let playlistsQuery = MPMediaQuery.playlists()
        var playlistsArray: [PlaylistData] = []
        
        if let allPlaylists = playlistsQuery.collections as? [MPMediaPlaylist] {
            for playlist in allPlaylists {
                let playlistSongs = playlist.items
                let totalPlayCount = playlistSongs.reduce(0) { $0 + ($1.playCount ?? 0) }
                
                let playlistData = PlaylistData(
                    name: playlist.name ?? "Unknown Playlist",
                    songs: playlistSongs,
                    totalPlayCount: totalPlayCount,
                    playlistID: playlist.persistentID
                )
                
                playlistsArray.append(playlistData)
            }
        }
        
        self.playlists = playlistsArray.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
}
