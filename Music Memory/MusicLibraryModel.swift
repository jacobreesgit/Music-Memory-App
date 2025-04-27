import SwiftUI
import MediaPlayer

class MusicLibraryModel: ObservableObject {
    @Published var songs: [MPMediaItem] = []
    @Published var albums: [AlbumData] = []
    @Published var artists: [ArtistData] = []
    @Published var isLoading: Bool = false
    @Published var hasAccess: Bool = false
    
    func requestPermissionAndLoadLibrary() {
        isLoading = true
        
        MPMediaLibrary.requestAuthorization { status in
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
    
    func loadLibrary() {
        // Get all songs
        let songsQuery = MPMediaQuery.songs()
        if let allSongs = songsQuery.items {
            self.songs = allSongs.sorted { 
                ($0.playCount ?? 0) > ($1.playCount ?? 0)
            }
        }
        
        // Process Albums
        let albumsQuery = MPMediaQuery.albums()
        var albumsDict: [String: AlbumData] = [:]
        
        if let allSongs = songsQuery.items {
            for song in allSongs {
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
        }
        
        self.albums = Array(albumsDict.values).sorted { $0.totalPlayCount > $1.totalPlayCount }
        
        // Process Artists
        var artistsDict: [String: ArtistData] = [:]
        
        if let allSongs = songsQuery.items {
            for song in allSongs {
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
        }
        
        self.artists = Array(artistsDict.values).sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
}