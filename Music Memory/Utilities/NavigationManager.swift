import SwiftUI
import MediaPlayer
import Combine

// A manager class to handle navigation between different parts of the app
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    // Published properties that views can observe
    @Published var navigateToSong: MPMediaItem? = nil
    @Published var navigateToAlbum: AlbumData? = nil
    @Published var navigateToArtist: ArtistData? = nil
    @Published var navigateToGenre: GenreData? = nil
    @Published var navigateToPlaylist: PlaylistData? = nil
    
    // Pending navigation request
    @Published var pendingNavigation: (type: String, id: String)? = nil
    
    private init() {
        // Listen for navigation notifications
        setupNotificationObserver()
    }
    
    // Set up observer for navigation requests
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("NavigateToDetailItem"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let userInfo = notification.userInfo,
               let type = userInfo["type"] as? String,
               let id = userInfo["id"] as? String {
                // Store the navigation request
                self.pendingNavigation = (type: type, id: id)
            }
        }
    }
    
    // Process navigation using the music library
    func processNavigation(using musicLibrary: MusicLibraryModel) {
        guard let navigation = pendingNavigation else { return }
        
        // Find and set the appropriate item based on the type and ID
        switch navigation.type {
        case "songs":
            if let songId = UInt64(navigation.id),
               let song = musicLibrary.songs.first(where: { $0.persistentID == songId }) {
                navigateToSong = song
            }
            
        case "albums":
            if let album = musicLibrary.albums.first(where: { $0.id == navigation.id }) {
                navigateToAlbum = album
            }
            
        case "artists":
            if let artist = musicLibrary.artists.first(where: { $0.id == navigation.id }) {
                navigateToArtist = artist
            }
            
        case "genres":
            if let genre = musicLibrary.genres.first(where: { $0.id == navigation.id }) {
                navigateToGenre = genre
            }
            
        case "playlists":
            if let playlist = musicLibrary.playlists.first(where: { $0.id == navigation.id }) {
                navigateToPlaylist = playlist
            }
            
        default:
            // Handle any other content types or invalid types
            print("Unknown content type for navigation: \(navigation.type)")
        }
        
        // Clear the pending navigation
        pendingNavigation = nil
    }
    
    // Reset navigation targets
    func resetNavigationTargets() {
        navigateToSong = nil
        navigateToAlbum = nil
        navigateToArtist = nil
        navigateToGenre = nil
        navigateToPlaylist = nil
    }
}
