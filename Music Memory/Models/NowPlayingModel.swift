// NowPlayingModel.swift
// Complete file with Dynamic Island integration and enhanced logging

import MediaPlayer
import Combine
import MusicKit
import UIKit
import ActivityKit  // New import for Live Activities
import os // For logging

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
    
    // Add a logger
    private let logger = Logger(subsystem: "com.jacobrees.MusicMemory", category: "NowPlayingModel")
    
    // MARK: - MusicLibrary reference for rank determination (made optional)
    var musicLibrary: MusicLibraryModel?
    
    // MARK: - Initialization
    init() {
        setupNowPlayingObserver()
        
        // Initialize with current state immediately
        updateCurrentSong()
        updatePlaybackState()
        
        // Force progress timer setup regardless of play state during initialization
        setupProgressTimer(forceUpdate: true)
    }
    
    // Add a method to set musicLibrary after initialization
    func setMusicLibrary(_ library: MusicLibraryModel) {
        self.musicLibrary = library
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
            
            // Log song info
            if let song = newSong {
                self.logger.info("Now playing: '\(song.title ?? "Unknown")' by '\(song.artist ?? "Unknown")' - ID: \(song.persistentID)")
                self.logger.info("Album: '\(song.albumTitle ?? "Unknown")' - Album Artist: '\(song.albumArtist ?? "Unknown")'")
                self.logger.info("Is cloud item: \(song.isCloudItem), Has asset URL: \(song.assetURL != nil)")
                
                // Log if the song has artwork
                if let artwork = song.artwork {
                    self.logger.info("Local artwork exists - Bounds: \(artwork.bounds.width)x\(artwork.bounds.height)")
                } else {
                    self.logger.info("No local artwork found for the song")
                }
            }
            
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
                
                // Check if the song is in our music library
                self.checkIfSongInLibrary()
                
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
    
    // Helper to check if the currently playing song is in our library model
    private func checkIfSongInLibrary() {
        guard let song = currentSong, let library = musicLibrary else { return }
        
        // Try to find this song in our library
        if let foundSong = library.songs.first(where: { $0.persistentID == song.persistentID }) {
            logger.info("Song found in library! Play count: \(foundSong.playCount)")
            
            // Log any artwork differences
            if foundSong.artwork != nil && song.artwork == nil {
                logger.info("Library version has artwork but current version doesn't")
            } else if foundSong.artwork == nil && song.artwork != nil {
                logger.info("Current version has artwork but library version doesn't")
            }
        } else {
            // Try to find a match by title and artist
            if let title = song.title, let artist = song.artist {
                let matchingLibrarySongs = library.songs.filter {
                    $0.title == title && $0.artist == artist
                }
                
                if !matchingLibrarySongs.isEmpty {
                    logger.info("Found \(matchingLibrarySongs.count) songs in library with same title/artist but different IDs")
                    
                    // Log the first matching song from library
                    if let firstMatch = matchingLibrarySongs.first {
                        logger.info("Library version: ID \(firstMatch.persistentID), Album: '\(firstMatch.albumTitle ?? "Unknown")' - Has artwork: \(firstMatch.artwork != nil)")
                    }
                } else {
                    logger.info("Song not found in library at all")
                }
            }
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
            logger.error("No current song when handling artwork")
            finishArtworkLoading(success: false)
            return
        }
        
        // Fast path 1: Check cache first (fastest path)
        if let title = song.title, let artist = song.artist, !title.isEmpty, !artist.isEmpty {
            let cacheKey = "\(title)-\(artist)"
            
            if let cachedImage = artworkCache[cacheKey] {
                logger.info("Using cached artwork for '\(title)' by '\(artist)'")
                self.artworkImage = cachedImage
                finishArtworkLoading(success: true)
                return
            }
        }
        
        // Try to find this exact song in our library first
        if let library = musicLibrary,
           let librarySong = library.songs.first(where: { $0.persistentID == song.persistentID }),
           let localArtwork = librarySong.artwork,
           let image = localArtwork.image(at: CGSize(width: 300, height: 300)) {
            
            logger.info("Found song in library with matching ID and artwork")
            self.artworkImage = image
            
            // Cache it for reuse
            if let title = song.title, let artist = song.artist {
                self.artworkCache["\(title)-\(artist)"] = image
            }
            
            finishArtworkLoading(success: true)
            return
        }
        
        // Fast path 2: Try to find a song in our library with matching title/artist/album
        if let library = musicLibrary,
           let title = song.title,
           let artist = song.artist,
           let albumTitle = song.albumTitle {
            
            // Try to match by title, artist AND album for highest accuracy
            let matchingSongs = library.songs.filter {
                $0.title == title &&
                $0.artist == artist &&
                $0.albumTitle == albumTitle &&
                $0.artwork != nil
            }
            
            if let bestMatch = matchingSongs.first,
               let localArtwork = bestMatch.artwork,
               let image = localArtwork.image(at: CGSize(width: 300, height: 300)) {
                
                logger.info("Found song in library with matching title/artist/album and artwork")
                self.artworkImage = image
                
                // Cache it for reuse
                self.artworkCache["\(title)-\(artist)"] = image
                
                finishArtworkLoading(success: true)
                return
            }
            
            // If no exact match, try just title and artist
            if matchingSongs.isEmpty {
                let titleArtistMatches = library.songs.filter {
                    $0.title == title &&
                    $0.artist == artist &&
                    $0.artwork != nil
                }
                
                if let bestMatch = titleArtistMatches.first,
                   let localArtwork = bestMatch.artwork,
                   let image = localArtwork.image(at: CGSize(width: 300, height: 300)) {
                    
                    logger.info("Found song in library with matching title/artist and artwork (different album)")
                    self.artworkImage = image
                    
                    // Cache it for reuse
                    self.artworkCache["\(title)-\(artist)"] = image
                    
                    finishArtworkLoading(success: true)
                    return
                }
            }
        }
        
        // Check if it's a streaming vs local track
        let isStreamingTrack = song.isCloudItem || song.assetURL == nil
        logger.info("Is streaming track: \(isStreamingTrack)")
        
        // For streaming tracks, skip straight to Apple Music search
        if isStreamingTrack {
            logger.info("Skipping directly to Apple Music search for streaming track")
            searchAppleMusicArtwork(forceImmediate: true)
            return
        }
        
        // Try the song's own artwork
        if let localArtwork = song.artwork {
            logger.info("Attempting to use song's own artwork")
            
            if let image = localArtwork.image(at: CGSize(width: 300, height: 300)) {
                logger.info("Successfully retrieved image from song's artwork")
                self.artworkImage = image
                
                // Cache it for reuse
                if let title = song.title, let artist = song.artist {
                    self.artworkCache["\(title)-\(artist)"] = image
                }
                
                finishArtworkLoading(success: true)
                return
            } else {
                logger.error("Failed to get image from song's artwork despite it existing")
            }
        } else {
            logger.info("Song has no artwork of its own")
        }
        
        // Only search Apple Music if absolutely necessary
        logger.info("Falling back to Apple Music search as last resort")
        searchAppleMusicArtwork(forceImmediate: false)
    }
    
    // MARK: - Apple Music Artwork Search
    private func searchAppleMusicArtwork(forceImmediate: Bool) {
        guard let song = currentSong,
              let title = song.title,
              let artist = song.artist,
              !title.isEmpty else {
            logger.error("Cannot search Apple Music: missing title or artist")
            finishArtworkLoading(success: false)
            return
        }
        
        let cacheKey = "\(title)-\(artist)"
        let albumInfo = song.albumTitle != nil ? " from album '\(song.albumTitle!)'" : ""
        logger.info("Searching Apple Music for '\(title)' by '\(artist)'\(albumInfo)")
        
        // Check authorization
        guard MusicAuthorization.currentStatus == .authorized else {
            logger.error("MusicKit not authorized")
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
                logger.info("Search query: \(query)")
                
                var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
                request.limit = forceImmediate ? 10 : 5
                
                let response = try await request.response()
                logger.info("Search returned \(response.songs.count) results")
                
                // Log the first few results
                for (index, song) in response.songs.prefix(3).enumerated() {
                    logger.info("Result \(index+1): '\(song.title)' by '\(song.artistName)' from '\(song.albumTitle ?? "Unknown")'")
                }
                
                // Enhanced matching to find the best match faster
                let bestMatch = findBestMatch(title: title, artist: artist, albumTitle: song.albumTitle, from: response.songs)
                
                if let bestMatch = bestMatch {
                    logger.info("Best match: '\(bestMatch.title)' by '\(bestMatch.artistName)' from '\(bestMatch.albumTitle ?? "Unknown")'")
                    
                    if let artworkUrl = bestMatch.artwork?.url(width: 300, height: 300) {
                        logger.info("Downloading artwork from URL")
                        
                        // Download the artwork
                        let (data, _) = try await URLSession.shared.data(from: artworkUrl)
                        if let image = UIImage(data: data) {
                            logger.info("Successfully downloaded artwork")
                            // Cache the image
                            self.artworkCache[cacheKey] = image
                            
                            await MainActor.run {
                                self.artworkImage = image
                                self.finishArtworkLoading(success: true)
                            }
                            return
                        } else {
                            logger.error("Failed to create image from downloaded data")
                        }
                    } else {
                        logger.error("Best match has no artwork URL")
                    }
                } else {
                    logger.error("No best match found among results")
                }
                
                // If we get here with no match from forceImmediate search, try a broader search
                if forceImmediate {
                    logger.info("Trying broader search terms")
                    self.searchAppleMusicWithBroaderTerms(title: title, artist: artist)
                } else {
                    await MainActor.run {
                        logger.error("Search failed to find suitable artwork")
                        self.finishArtworkLoading(success: false)
                    }
                }
            } catch {
                logger.error("Search error: \(error.localizedDescription)")
                
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
        logger.info("Searching with broader terms, using just title: '\(title)'")
        
        Task {
            do {
                // Try with just the title for better results
                let simpleQuery = title
                
                var request = MusicCatalogSearchRequest(term: simpleQuery, types: [Song.self])
                request.limit = 15
                
                let response = try await request.response()
                logger.info("Broader search returned \(response.songs.count) results")
                
                // Log the first few results
                for (index, song) in response.songs.prefix(3).enumerated() {
                    logger.info("Result \(index+1): '\(song.title)' by '\(song.artistName)' from '\(song.albumTitle ?? "Unknown")'")
                }
                
                if let bestMatch = findBestMatch(title: title, artist: artist, albumTitle: nil, from: response.songs),
                   let artworkUrl = bestMatch.artwork?.url(width: 300, height: 300) {
                    
                    logger.info("Best match from broader search: '\(bestMatch.title)' by '\(bestMatch.artistName)' from '\(bestMatch.albumTitle ?? "Unknown")'")
                    
                    // Download the artwork
                    let (data, _) = try await URLSession.shared.data(from: artworkUrl)
                    if let image = UIImage(data: data) {
                        logger.info("Successfully downloaded artwork from broader search")
                        // Cache the image
                        self.artworkCache[cacheKey] = image
                        
                        await MainActor.run {
                            self.artworkImage = image
                            self.finishArtworkLoading(success: true)
                        }
                        return
                    } else {
                        logger.error("Failed to create image from downloaded data in broader search")
                    }
                } else {
                    logger.error("No best match found in broader search results")
                }
                
                await MainActor.run {
                    self.finishArtworkLoading(success: false)
                }
            } catch {
                logger.error("Broader search error: \(error.localizedDescription)")
                await MainActor.run {
                    self.finishArtworkLoading(success: false)
                }
            }
        }
    }
    
    // Enhanced algorithm to find the best match faster with album consideration
    private func findBestMatch(title: String, artist: String, albumTitle: String?, from songs: MusicItemCollection<Song>) -> Song? {
        // If no songs have artwork, return nil immediately
        guard songs.contains(where: { $0.artwork != nil }) else {
            logger.info("No songs with artwork found in results")
            return nil
        }
        
        // First look for exact matches with title, artist AND album (most specific)
        if let album = albumTitle, !album.isEmpty {
            let exactAlbumMatches = songs.filter { song in
                song.title.lowercased() == title.lowercased() &&
                song.artistName.lowercased() == artist.lowercased() &&
                (song.albumTitle?.lowercased() == album.lowercased()) &&
                song.artwork != nil
            }
            
            if let bestAlbumMatch = exactAlbumMatches.first {
                logger.info("Found exact match with title, artist, AND album")
                return bestAlbumMatch
            }
        }
        
        // Then look for title+artist exact matches
        let exactMatches = songs.filter { song in
            song.title.lowercased() == title.lowercased() &&
            song.artistName.lowercased() == artist.lowercased() &&
            song.artwork != nil
        }
        
        if let firstExactMatch = exactMatches.first {
            logger.info("Found exact match with title and artist")
            return firstExactMatch
        }
        
        // Then try title-only exact matches
        let titleMatches = songs.filter { song in
            song.title.lowercased() == title.lowercased() &&
            song.artwork != nil
        }
        
        if let firstTitleMatch = titleMatches.first {
            logger.info("Found exact match with title only")
            return firstTitleMatch
        }
        
        // Then try partial matches with both title and artist
        let partialMatches = songs.filter { song in
            song.title.lowercased().contains(title.lowercased()) &&
            song.artistName.lowercased().contains(artist.lowercased()) &&
            song.artwork != nil
        }
        
        if let firstPartialMatch = partialMatches.first {
            logger.info("Found partial match with title and artist")
            return firstPartialMatch
        }
        
        // Finally, just return any song with artwork
        logger.info("No good matches, returning first result with artwork")
        return songs.first(where: { $0.artwork != nil })
    }
    
    private func finishArtworkLoading(success: Bool) {
        logger.info("Finished artwork loading, success: \(success)")
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
