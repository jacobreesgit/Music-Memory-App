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
    @Published var searchResults: [Song] = []
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        Task {
            let status = await MusicAuthorization.currentStatus
            
            DispatchQueue.main.async {
                self.authorizationStatus = status
                self.isAuthorized = status == .authorized
                
                // Check if the user has an Apple Music subscription
                if status == .authorized {
                    self.checkSubscriptionStatus()
                }
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
        // Check if the user has an Apple Music subscription
        // This is a simplified approach - in a real app, you'd verify capabilities more thoroughly
        Task {
            do {
                let storefront = try await MusicDataRequest<Storefront>.currentStorefront()
                
                await MainActor.run {
                    self.isSubscribed = storefront != nil
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
                self.searchResults = []
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
                self.searchResults = []
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
            var results = response.songs
            
            // Filter to keep only likely versions of the same song
            results = filterVersionsOfSong(librarySong: librarySong,
                                          catalogSongs: results,
                                          includeRemixes: includeRemixes)
            
            await MainActor.run {
                self.isSearching = false
            }
            
            return results
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
            
            let isAcousticVersion = song.title.lowercased().contains("acoustic") ||
                                  (song.albumTitle?.lowercased().contains("acoustic") ?? false)
            
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
    
    func createPlaylist(name: String, description: String?, songs: [Song]) async -> Bool {
        do {
            // Create the playlist
            let creationRequest = MusicLibraryPlaylistCreationRequest(
                name: name,
                description: description ?? "Created by Music Memory",
                items: songs.map { MusicItemProperty($0) }
            )
            
            _ = try await creationRequest.response()
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
            // Add song to library
            let addRequest = MusicLibraryAddRequest(items: [song])
            _ = try await addRequest.response()
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
