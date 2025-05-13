// NowPlayingModel.swift
// Complete file with Dynamic Island integration

import MediaPlayer
import Combine
import MusicKit
import UIKit
import ActivityKit  // New import for Live Activities

class NowPlayingModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSong: MPMediaItem?
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    @Published var artworkImage: UIImage?
    @Published var isLoadingArtwork: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var progressTimer: Timer?
    private var artworkTask: Task<Void, Never>?
    private var artworkCache: [String: UIImage] = [:]
    private var previousSongID: MPMediaEntityPersistentID?
    
    // MARK: - Initialization
    init() {
        setupNowPlayingObserver()
        
        // Initialize with current state immediately
        updateCurrentSong()
        updatePlaybackState()
        
        // Force progress timer setup regardless of play state during initialization
        setupProgressTimer(forceUpdate: true)
    }
    
    // MARK: - Now Playing Observer
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
    }
    
    // MARK: - Update Methods
    private func updateCurrentSong() {
        // Cancel any existing artwork task
        artworkTask?.cancel()
        
        DispatchQueue.main.async {
            // Get the new song
            let newSong = self.musicPlayer.nowPlayingItem
            let newSongID = newSong?.persistentID
            
            // Check if song actually changed
            if newSongID != self.previousSongID {
                // Clear previous artwork when song changes
                self.artworkImage = nil
                self.isLoadingArtwork = true
                self.previousSongID = newSongID
                
                // Set the new song
                self.currentSong = newSong
                
                // Update progress immediately with current position
                if self.musicPlayer.playbackState == .playing && newSong != nil {
                    self.playbackProgress = min(self.musicPlayer.currentPlaybackTime /
                        (newSong?.playbackDuration ?? 1.0), 1.0)
                } else {
                    self.playbackProgress = 0.0
                }
                
                self.setupProgressTimer()
                
                // Immediately start artwork loading with fast path detection
                self.handleArtworkWithFastPath()
            } else if newSong != nil {
                // Even if song didn't change, update progress for initial load
                self.playbackProgress = min(self.musicPlayer.currentPlaybackTime /
                    (newSong?.playbackDuration ?? 1.0), 1.0)
            }
            
            // Update the Dynamic Island
            self.updateDynamicIsland()
        }
    }
    
    private func updatePlaybackState() {
        DispatchQueue.main.async {
            let newState = self.musicPlayer.playbackState == .playing
            if self.isPlaying != newState {
                self.isPlaying = newState
            }
            
            // Always update the progress when playback state changes
            if self.currentSong != nil {
                self.playbackProgress = min(self.musicPlayer.currentPlaybackTime /
                    (self.currentSong?.playbackDuration ?? 1.0), 1.0)
            }
            
            self.setupProgressTimer()
            
            // Update the Dynamic Island
            self.updateDynamicIsland()
        }
    }
    
    // MARK: - Fast Path Artwork Handling
    private func handleArtworkWithFastPath() {
        guard let song = currentSong else {
            finishArtworkLoading(success: false)
            return
        }
        
        // Fast path 1: Check cache first (fastest path)
        if let title = song.title, let artist = song.artist, !title.isEmpty, !artist.isEmpty {
            let cacheKey = "\(title)-\(artist)"
            
            if let cachedImage = artworkCache[cacheKey] {
                self.artworkImage = cachedImage
                finishArtworkLoading(success: true)
                return
            }
        }
        
        // Fast path 2: Quick check for streaming vs local track
        let isStreamingTrack = song.isCloudItem || song.assetURL == nil
        
        // For streaming tracks, skip straight to Apple Music search
        if isStreamingTrack {
            // Skip local artwork check for streaming tracks
            searchAppleMusicArtwork(forceImmediate: true)
            return
        }
        
        // Fast path 3: Local artwork check (only for real local tracks)
        if let localArtwork = song.artwork,
           localArtwork.bounds.width > 10,
           let image = localArtwork.image(at: CGSize(width: 300, height: 300)) {
            
            self.artworkImage = image
            
            // Cache it for reuse
            if let title = song.title, let artist = song.artist {
                self.artworkCache["\(title)-\(artist)"] = image
            }
            
            finishArtworkLoading(success: true)
            return
        }
        
        // Default path: Search Apple Music
        searchAppleMusicArtwork(forceImmediate: false)
    }
    
    // MARK: - Apple Music Artwork Search
    private func searchAppleMusicArtwork(forceImmediate: Bool) {
        guard let song = currentSong,
              let title = song.title,
              let artist = song.artist,
              !title.isEmpty else {
            finishArtworkLoading(success: false)
            return
        }
        
        let cacheKey = "\(title)-\(artist)"
        
        // Check authorization
        guard MusicAuthorization.currentStatus == .authorized else {
            finishArtworkLoading(success: false)
            return
        }
        
        // Cancel any existing task
        artworkTask?.cancel()
        
        // Create a new task to search for the song
        artworkTask = Task {
            do {
                // Streamline query for better performance
                // Don't use quotes for immediate search to get better results
                let query = forceImmediate ? "\(title) \(artist)" : "\"\(title)\" \"\(artist)\""
                
                var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
                request.limit = forceImmediate ? 10 : 5
                
                let response = try await request.response()
                
                // Enhanced matching to find the best artwork faster
                let bestMatch = findBestMatch(title: title, artist: artist, from: response.songs)
                
                if let bestMatch = bestMatch,
                   let artworkUrl = bestMatch.artwork?.url(width: 300, height: 300) {
                    
                    // Download the artwork
                    let (data, _) = try await URLSession.shared.data(from: artworkUrl)
                    if let image = UIImage(data: data) {
                        // Cache the image
                        self.artworkCache[cacheKey] = image
                        
                        await MainActor.run {
                            self.artworkImage = image
                            self.finishArtworkLoading(success: true)
                        }
                        return
                    }
                }
                
                // If we get here with no match from forceImmediate search, try a broader search
                if forceImmediate {
                    self.searchAppleMusicWithBroaderTerms(title: title, artist: artist)
                } else {
                    await MainActor.run {
                        self.finishArtworkLoading(success: false)
                    }
                }
            } catch {
                // In case of error, try a broader search for streaming tracks
                if forceImmediate {
                    self.searchAppleMusicWithBroaderTerms(title: title, artist: artist)
                } else {
                    await MainActor.run {
                        self.finishArtworkLoading(success: false)
                    }
                }
            }
        }
    }
    
    // Immediately try a broader search instead of waiting for retries
    private func searchAppleMusicWithBroaderTerms(title: String, artist: String) {
        let cacheKey = "\(title)-\(artist)"
        
        Task {
            do {
                // Try with just the title for better results
                let simpleQuery = title
                
                var request = MusicCatalogSearchRequest(term: simpleQuery, types: [Song.self])
                request.limit = 15
                
                let response = try await request.response()
                
                if let bestMatch = findBestMatch(title: title, artist: artist, from: response.songs),
                   let artworkUrl = bestMatch.artwork?.url(width: 300, height: 300) {
                    
                    // Download the artwork
                    let (data, _) = try await URLSession.shared.data(from: artworkUrl)
                    if let image = UIImage(data: data) {
                        // Cache the image
                        self.artworkCache[cacheKey] = image
                        
                        await MainActor.run {
                            self.artworkImage = image
                            self.finishArtworkLoading(success: true)
                        }
                        return
                    }
                }
                
                await MainActor.run {
                    self.finishArtworkLoading(success: false)
                }
            } catch {
                await MainActor.run {
                    self.finishArtworkLoading(success: false)
                }
            }
        }
    }
    
    // Enhanced algorithm to find the best match faster
    private func findBestMatch(title: String, artist: String, from songs: MusicItemCollection<Song>) -> Song? {
        // If no songs have artwork, return nil immediately
        guard songs.contains(where: { $0.artwork != nil }) else {
            return nil
        }
        
        // First look for exact matches
        let exactMatches = songs.filter { song in
            song.title.lowercased() == title.lowercased() &&
            song.artistName.lowercased() == artist.lowercased() &&
            song.artwork != nil
        }
        
        if let firstExactMatch = exactMatches.first {
            return firstExactMatch
        }
        
        // Then try title-only exact matches
        let titleMatches = songs.filter { song in
            song.title.lowercased() == title.lowercased() &&
            song.artwork != nil
        }
        
        if let firstTitleMatch = titleMatches.first {
            return firstTitleMatch
        }
        
        // Then try partial matches with both title and artist
        let partialMatches = songs.filter { song in
            song.title.lowercased().contains(title.lowercased()) &&
            song.artistName.lowercased().contains(artist.lowercased()) &&
            song.artwork != nil
        }
        
        if let firstPartialMatch = partialMatches.first {
            return firstPartialMatch
        }
        
        // Finally, just return any song with artwork
        return songs.first(where: { $0.artwork != nil })
    }
    
    private func finishArtworkLoading(success: Bool) {
        self.isLoadingArtwork = false
    }
    
    // MARK: - Progress Timer
    private func setupProgressTimer(forceUpdate: Bool = false) {
        // Clear existing timer
        progressTimer?.invalidate()
        progressTimer = nil
        
        // Set up timer if playing or force update is requested
        guard (isPlaying || forceUpdate),
              let song = currentSong,
              song.playbackDuration > 0 else {
            return
        }
        
        // Update progress once immediately
        playbackProgress = min(musicPlayer.currentPlaybackTime / song.playbackDuration, 1.0)
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let song = self.currentSong else { return }
            
            let currentPlaybackTime = self.musicPlayer.currentPlaybackTime
            self.playbackProgress = min(currentPlaybackTime / song.playbackDuration, 1.0)
            
            // Update the Dynamic Island when progress changes
            if self.playbackProgress > 0 {
                self.updateDynamicIsland()
            }
        }
    }
    
    // MARK: - Player Controls
    func togglePlayPause() {
        if isPlaying {
            musicPlayer.pause()
        } else {
            musicPlayer.play()
        }
        
        // Update Dynamic Island after play/pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateDynamicIsland()
        }
    }
    
    func nextTrack() {
        musicPlayer.skipToNextItem()
        
        // Update Dynamic Island after skipping track
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateDynamicIsland()
        }
    }
    
    func previousTrack() {
        musicPlayer.skipToPreviousItem()
        
        // Update Dynamic Island after skipping track
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateDynamicIsland()
        }
    }
    
    // Limit cache size periodically
    private func cleanupCache() {
        if artworkCache.count > 75 {
            // Keep just the 50 most recent items
            let sortedKeys = artworkCache.keys.sorted()
            let keysToRemove = sortedKeys.prefix(sortedKeys.count - 50)
            keysToRemove.forEach { artworkCache.removeValue(forKey: $0) }
        }
    }
    
    deinit {
        progressTimer?.invalidate()
        musicPlayer.endGeneratingPlaybackNotifications()
        artworkTask?.cancel()
        
        // End Dynamic Island activity when model is deinitialized
        endActivity()
    }
}
