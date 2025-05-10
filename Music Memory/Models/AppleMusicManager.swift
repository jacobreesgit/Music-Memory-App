//
//  AppleMusicManager.swift
//  Music Memory
//
//  Created by Jacob Rees on 10/05/2025.
//

import Foundation
import MusicKit
import MediaPlayer
import Combine

class AppleMusicManager: ObservableObject {
    static let shared = AppleMusicManager()
    
    @Published var isAuthorized = false
    @Published var isSubscribed = false
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var isSearching = false
    @Published var searchResults: MusicItemCollection<Song> = MusicItemCollection<Song>([])
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        Task { @MainActor in
            let status = MusicAuthorization.currentStatus
            
            self.authorizationStatus = status
            self.isAuthorized = status == .authorized
            
            // Check if the user has an Apple Music subscription
            if status == .authorized {
                self.checkSubscriptionStatus()
            }
        }
    }
    
    func requestAuthorization() async -> MusicAuthorization.Status {
        let status = await MusicAuthorization.request()
        
        await MainActor.run {
            self.authorizationStatus = status
            self.isAuthorized = status == .authorized
            
            if status == .authorized {
                self.checkSubscriptionStatus()
            }
        }
        
        return status
    }
    
    private func checkSubscriptionStatus() {
        Task {
            do {
                // Use the correct subscription status check
                let subscription = try await MusicSubscription.current
                
                await MainActor.run {
                    self.isSubscribed = subscription.subscriptionStatus == .active
                }
            } catch {
                print("Error checking subscription status: \(error.localizedDescription)")
                await MainActor.run {
                    self.isSubscribed = false
                    self.error = error
                }
            }
        }
    }
    
    func searchAppleMusic(for query: String, limit: Int = 25) async {
        // Don't search if query is empty or too short
        guard !query.isEmpty && query.count >= 2 else {
            await MainActor.run {
                self.searchResults = MusicItemCollection<Song>([])
                self.isSearching = false
            }
            return
        }
        
        await MainActor.run {
            self.isSearching = true
            self.error = nil
        }
        
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = limit
            
            let response = try await request.response()
            
            await MainActor.run {
                self.searchResults = response.songs
                self.isSearching = false
            }
        } catch {
            print("Error searching Apple Music: \(error.localizedDescription)")
            await MainActor.run {
                self.searchResults = MusicItemCollection<Song>([])
                self.isSearching = false
                self.error = error
            }
        }
    }
    
    func findVersionsForSong(_ librarySong: MPMediaItem, includeRemixes: Bool = false) async -> [Song] {
        await MainActor.run {
            self.isSearching = true
            self.error = nil
        }
        
        // Create a search query that's likely to find versions of the same song
        let songTitle = librarySong.title ?? ""
        let artistName = librarySong.artist ?? ""
        
        // Skip if we don't have enough info
        guard !songTitle.isEmpty, !artistName.isEmpty else {
            await MainActor.run {
                self.isSearching = false
            }
            return []
        }
        
        // Formulate a search that will likely find versions of the same track
        let query = "\(songTitle) \(artistName)"
        
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = 20
            
            let response = try await request.response()
            
            // Convert MusicItemCollection to Array
            let songsArray = response.songs.compactMap { $0 }
            
            // Filter to keep only likely versions of the same song
            let filteredResults = filterVersionsOfSong(
                librarySong: librarySong,
                catalogSongs: songsArray,
                includeRemixes: includeRemixes
            )
            
            await MainActor.run {
                self.isSearching = false
            }
            
            return filteredResults
        } catch {
            print("Error finding versions: \(error.localizedDescription)")
            await MainActor.run {
                self.isSearching = false
                self.error = error
            }
            return []
        }
    }
    
    private func filterVersionsOfSong(librarySong: MPMediaItem, catalogSongs: [Song], includeRemixes: Bool) -> [Song] {
        let songTitle = librarySong.title ?? ""
        let artistName = librarySong.artist ?? ""
        let songDuration = librarySong.playbackDuration
        
        // Filter based on song title and artist match
        return catalogSongs.filter { song in
            // Basic filtering criteria
            let titleMatches = song.title.lowercased().contains(songTitle.lowercased()) ||
                               songTitle.lowercased().contains(song.title.lowercased())
            
            let artistMatches = song.artistName.lowercased().contains(artistName.lowercased()) ||
                                artistName.lowercased().contains(song.artistName.lowercased())
            
            // Duration similarity threshold (20 seconds)
            let durationDifference = abs(song.duration ?? 0 - songDuration)
            let durationSimilar = durationDifference < 20.0
            
            // Keywords that might indicate different versions
            let isLiveVersion = song.title.lowercased().contains("live") ||
                              (song.albumTitle?.lowercased().contains("live") ?? false)
            
            let isRemixVersion = song.title.lowercased().contains("remix") ||
                               (song.albumTitle?.lowercased().contains("remix") ?? false)
            
            // Include or exclude remixes based on parameter
            let remixCriteria = includeRemixes || !isRemixVersion
            
            // We want to include studio, remastered, and maybe acoustic versions,
            // but generally exclude live versions unless specifically searching for them
            let versionCriteria = !isLiveVersion || song.title.lowercased() == songTitle.lowercased()
            
            return titleMatches && artistMatches && (durationSimilar || isRemixVersion) && remixCriteria && versionCriteria
        }
    }
    
    // MARK: - Actual Implementation for Creating Playlists and Adding Songs
    
    func createPlaylist(name: String, description: String?, songs: [Song]) async -> Bool {
        do {
            // Use underscore to ignore the returned playlist and suppress warning
            _ = try await MusicLibrary.shared.createPlaylist(
                name: name,
                description: description ?? "Created by Music Memory",
                items: songs
            )
            
            print("Successfully created playlist: \(name) with \(songs.count) songs")
            return true
        } catch {
            print("Error creating playlist: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
            return false
        }
    }
    
    func addSongToLibrary(_ song: Song) async -> Bool {
        do {
            // Pass the individual song directly, not as an array
            try await MusicLibrary.shared.add(song)
            print("Successfully added song to library: \(song.title)")
            return true
        } catch {
            print("Error adding song to library: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
            return false
        }
    }
}
