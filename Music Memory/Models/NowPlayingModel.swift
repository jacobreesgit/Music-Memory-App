//
//  NowPlayingModel.swift
//  Music Memory
//
//  Created on 13/05/2025.
//

import MediaPlayer
import Combine
import MusicKit
import UIKit

class NowPlayingModel: ObservableObject {
    @Published var currentSong: MPMediaItem?
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    @Published var fetchedArtwork: UIImage? = nil
    @Published var isLoadingArtwork: Bool = false
    
    // BUGFIX: Added artwork version UUID to force SwiftUI view updates
    // This will change whenever artwork changes, even when the song remains the same
    // SwiftUI optimizes by not redrawing views if identities haven't changed
    @Published var artworkVersion = UUID()
    
    // Simple cache for artwork
    private var artworkCache: [String: UIImage] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var progressTimer: Timer?
    private var artworkTask: Task<Void, Never>?
    private var retryCount = 0
    private let maxRetries = 2
    
    init() {
        setupNowPlayingObserver()
    }
    
    private func setupNowPlayingObserver() {
        // Register for notifications
        NotificationCenter.default.publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
            .sink { [weak self] _ in
                self?.updateCurrentSong()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .MPMusicPlayerControllerPlaybackStateDidChange)
            .sink { [weak self] _ in
                self?.updatePlaybackState()
            }
            .store(in: &cancellables)
        
        // Begin receiving notifications
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        // Initialize with current state
        updateCurrentSong()
        updatePlaybackState()
    }
    
    private func updateCurrentSong() {
        DispatchQueue.main.async {
            // Explicitly clear any existing fetched artwork immediately
            self.fetchedArtwork = nil
            self.isLoadingArtwork = true
            self.retryCount = 0
            
            // Update current song
            self.currentSong = self.musicPlayer.nowPlayingItem
            
            // Reset progress
            self.playbackProgress = 0.0
            self.setupProgressTimer()
            
            // Check if local artwork is available
            if self.currentSong?.artwork != nil {
                // If we have local artwork, no need to fetch external
                self.isLoadingArtwork = false
            } else {
                // Try to fetch artwork if local artwork isn't available
                self.fetchArtworkForCurrentSong()
            }
        }
    }
    
    // Method to fetch artwork from Apple Music
    private func fetchArtworkForCurrentSong() {
        // Cancel any previous task
        artworkTask?.cancel()
        
        // Only proceed if we have song details
        guard let songTitle = currentSong?.title,
              let artistName = currentSong?.artist else {
            DispatchQueue.main.async {
                self.isLoadingArtwork = false
            }
            return
        }
        
        // Create a cache key
        let cacheKey = "\(songTitle)-\(artistName)"
        
        // Check if artwork is in the cache
        if let cachedArtwork = artworkCache[cacheKey] {
            DispatchQueue.main.async {
                self.fetchedArtwork = cachedArtwork
                
                // BUGFIX: Update the artwork version when setting cached artwork
                // This ensures SwiftUI refreshes the view even if the song hasn't changed
                self.artworkVersion = UUID()
                
                self.isLoadingArtwork = false
            }
            return
        }
        
        // Create search query from song details
        // Add quotes to make exact match more likely
        let query = "\"\(songTitle)\" \"\(artistName)\""
        
        // Start a new task to search for the song
        artworkTask = Task {
            do {
                // Check if Apple Music is authorized
                if MusicAuthorization.currentStatus != .authorized {
                    // We can't fetch artwork without authorization
                    await MainActor.run {
                        self.isLoadingArtwork = false
                    }
                    return
                }
                
                // Create search request
                var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
                request.limit = 5  // Increased to improve chances of a match
                
                // Send request
                let response = try await request.response()
                
                // Find matching song with artwork
                // Try to find an exact match first
                let exactMatches = response.songs.filter { song in
                    let titleMatch = song.title.lowercased() == songTitle.lowercased()
                    let artistMatch = song.artistName.lowercased() == artistName.lowercased()
                    return titleMatch && artistMatch
                }
                
                // If we have exact matches, use the first one with artwork
                if let match = exactMatches.first(where: { $0.artwork != nil }),
                   let artworkUrl = match.artwork?.url(width: 300, height: 300) {
                    // Download artwork image
                    let (data, _) = try await URLSession.shared.data(from: artworkUrl)
                    if let image = UIImage(data: data) {
                        // Cache the artwork
                        self.artworkCache[cacheKey] = image
                        
                        // Update UI on main thread
                        await MainActor.run {
                            self.fetchedArtwork = image
                            
                            // BUGFIX: Create a new UUID to force SwiftUI view refresh
                            // This is crucial - without this, SwiftUI may not redraw the image
                            // because the song's persistentID hasn't changed
                            self.artworkVersion = UUID()
                            
                            self.isLoadingArtwork = false
                            print("🎵 Exact match artwork updated: \(cacheKey)")
                        }
                        return
                    }
                }
                
                // If no exact match, try partial matches
                if let firstSong = response.songs.first(where: { $0.artwork != nil }),
                   let artworkUrl = firstSong.artwork?.url(width: 300, height: 300) {
                    
                    // Download artwork image
                    let (data, _) = try await URLSession.shared.data(from: artworkUrl)
                    if let image = UIImage(data: data) {
                        // Cache the artwork
                        self.artworkCache[cacheKey] = image
                        
                        // Update UI on main thread
                        await MainActor.run {
                            self.fetchedArtwork = image
                            
                            // BUGFIX: Same UUID update for partial matches
                            self.artworkVersion = UUID()
                            
                            self.isLoadingArtwork = false
                            print("🎵 Partial match artwork updated: \(cacheKey)")
                        }
                        return
                    }
                }
                
                // If we got here, we didn't find suitable artwork
                // Try a different search strategy if this is the first attempt
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    
                    // Try with a simplified query
                    let simpleQuery = songTitle
                    await self.retryArtworkSearch(simpleQuery: simpleQuery, cacheKey: cacheKey)
                } else {
                    // Give up after max retries
                    await MainActor.run {
                        self.isLoadingArtwork = false
                    }
                }
            } catch {
                print("Error fetching artwork: \(error.localizedDescription)")
                
                // Try again with a simpler query if this is the first attempt
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    await self.retryArtworkSearch(simpleQuery: songTitle, cacheKey: cacheKey)
                } else {
                    await MainActor.run {
                        self.isLoadingArtwork = false
                    }
                }
            }
        }
    }
    
    // Helper method to retry artwork search with a simplified query
    private func retryArtworkSearch(simpleQuery: String, cacheKey: String) async {
        do {
            var request = MusicCatalogSearchRequest(term: simpleQuery, types: [Song.self])
            request.limit = 10
            
            let response = try await request.response()
            
            if let firstSong = response.songs.first(where: { $0.artwork != nil }),
               let artworkUrl = firstSong.artwork?.url(width: 300, height: 300) {
                
                let (data, _) = try await URLSession.shared.data(from: artworkUrl)
                if let image = UIImage(data: data) {
                    // Cache the artwork
                    self.artworkCache[cacheKey] = image
                    
                    await MainActor.run {
                        self.fetchedArtwork = image
                        
                        // BUGFIX: Update artwork version for retry fetches too
                        self.artworkVersion = UUID()
                        
                        self.isLoadingArtwork = false
                        print("🎵 Retry match artwork updated: \(cacheKey)")
                    }
                    return
                }
            }
            
            // If we reach here, we still couldn't find artwork
            await MainActor.run {
                self.isLoadingArtwork = false
            }
        } catch {
            print("Error in retry artwork search: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoadingArtwork = false
            }
        }
    }
    
    private func updatePlaybackState() {
        DispatchQueue.main.async {
            self.isPlaying = self.musicPlayer.playbackState == .playing
            self.setupProgressTimer()
        }
    }
    
    private func setupProgressTimer() {
        // Clear existing timer
        progressTimer?.invalidate()
        progressTimer = nil
        
        // Only set up timer if playing
        guard isPlaying, currentSong != nil, let song = currentSong, song.playbackDuration > 0 else { return }
        
        // Update more frequently for smoother animation
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Get actual playback time directly from the music player
            let currentPlaybackTime = self.musicPlayer.currentPlaybackTime
            self.playbackProgress = min(currentPlaybackTime / song.playbackDuration, 1.0)
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            musicPlayer.pause()
        } else {
            musicPlayer.play()
        }
    }
    
    func nextTrack() {
        musicPlayer.skipToNextItem()
    }
    
    func previousTrack() {
        musicPlayer.skipToPreviousItem()
    }
    
    // Limit cache size
    private func cleanupCache() {
        if artworkCache.count > 50 {
            // Remove oldest entries - fixed the syntax error here
            artworkCache = Dictionary(uniqueKeysWithValues: artworkCache.suffix(25))
        }
    }
    
    deinit {
        progressTimer?.invalidate()
        musicPlayer.endGeneratingPlaybackNotifications()
        artworkTask?.cancel()
    }
}
