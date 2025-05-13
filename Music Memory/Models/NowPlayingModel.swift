// NowPlayingModel.swift - Fixed to ensure track navigation works properly
import MediaPlayer
import Combine
import MusicKit
import UIKit

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
    private var lastManualAction = Date()
    private var retryCount = 0
    private let maxRetries = 2
    
    // MARK: - Initialization
    init() {
        setupNowPlayingObserver()
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
        
        // Initialize with current state
        updateCurrentSong()
        updatePlaybackState()
    }
    
    // MARK: - Update Methods
    private func updateCurrentSong() {
        // Cancel any existing artwork task
        artworkTask?.cancel()
        
        DispatchQueue.main.async {
            #if DEBUG
            print("🔄 Now playing item changed")
            #endif
            
            // Get the new song
            let newSong = self.musicPlayer.nowPlayingItem
            let newSongID = newSong?.persistentID
            
            // Check if song actually changed
            if newSongID != self.previousSongID {
                #if DEBUG
                print("🎵 New song detected: \(newSong?.title ?? "Unknown") - \(newSong?.artist ?? "Unknown")")
                #endif
                
                // Clear previous artwork when song changes
                self.artworkImage = nil
                self.isLoadingArtwork = true
                self.retryCount = 0
                self.previousSongID = newSongID
                
                // Set the new song
                self.currentSong = newSong
                
                // Reset progress
                self.playbackProgress = 0.0
                self.setupProgressTimer()
                
                // Immediately start artwork loading
                self.handleArtworkForCurrentSong()
            }
        }
    }
    
    private func updatePlaybackState() {
        DispatchQueue.main.async {
            let newState = self.musicPlayer.playbackState == .playing
            if self.isPlaying != newState {
                #if DEBUG
                print("▶️ Playback state changed: \(newState ? "Playing" : "Paused")")
                #endif
                self.isPlaying = newState
            }
            self.setupProgressTimer()
        }
    }
    
    // MARK: - Artwork Handling
    private func handleArtworkForCurrentSong() {
        guard let song = currentSong else {
            finishArtworkLoading(success: false)
            return
        }
        
        #if DEBUG
        let debugInfo = """
        📊 Song details:
          - Title: \(song.title ?? "Unknown")
          - Artist: \(song.artist ?? "Unknown")
          - PersistentID: \(song.persistentID)
          - CloudItem: \(song.isCloudItem)
          - HasAssetURL: \(song.assetURL != nil)
        """
        print(debugInfo)
        #endif
        
        // First check cache using a consistent key format
        if let title = song.title, let artist = song.artist {
            let cacheKey = "\(title)-\(artist)"
            
            if let cachedImage = artworkCache[cacheKey] {
                #if DEBUG
                print("🖼️ Using cached artwork for: \(cacheKey)")
                #endif
                
                self.artworkImage = cachedImage
                finishArtworkLoading(success: true)
                return
            }
        }
        
        // Try to get artwork from song (most likely won't work based on logs)
        if let localArtwork = song.artwork {
            let bounds = localArtwork.bounds
            
            #if DEBUG
            print("🔎 Artwork bounds: \(bounds.width)x\(bounds.height)")
            #endif
            
            // Only proceed if artwork has valid dimensions
            if bounds.width > 10 && bounds.height > 10,
               let image = localArtwork.image(at: CGSize(width: 300, height: 300)) {
                #if DEBUG
                print("✅ Using valid local artwork")
                #endif
                
                self.artworkImage = image
                
                // Cache it for reuse
                if let title = song.title, let artist = song.artist {
                    self.artworkCache["\(title)-\(artist)"] = image
                }
                
                finishArtworkLoading(success: true)
                return
            } else {
                #if DEBUG
                print("⚠️ Invalid local artwork dimensions: \(bounds.width)x\(bounds.height)")
                #endif
            }
        }
        
        // As a last resort, search Apple Music
        searchAppleMusicArtwork()
    }
    
    private func searchAppleMusicArtwork() {
        guard let song = currentSong,
              let title = song.title,
              let artist = song.artist else {
            finishArtworkLoading(success: false)
            return
        }
        
        let cacheKey = "\(title)-\(artist)"
        
        // Check authorization
        guard MusicAuthorization.currentStatus == .authorized else {
            #if DEBUG
            print("⚠️ Not authorized for Apple Music API")
            #endif
            finishArtworkLoading(success: false)
            return
        }
        
        #if DEBUG
        print("🔍 Searching Apple Music for: \"\(title)\" \"\(artist)\"")
        #endif
        
        // Cancel any existing task
        artworkTask?.cancel()
        
        // Create a new task to search for the song
        artworkTask = Task {
            do {
                // Use a more specific query with quotes for exact matching
                let query = "\"\(title)\" \"\(artist)\""
                
                var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
                request.limit = 5
                
                let response = try await request.response()
                
                // Check if we found a matching song with artwork
                if let matchingSong = response.songs.first(where: { $0.artwork != nil }),
                   let artworkUrl = matchingSong.artwork?.url(width: 300, height: 300) {
                    
                    #if DEBUG
                    print("🖼️ Found Apple Music artwork URL: \(artworkUrl)")
                    #endif
                    
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
                
                // Try again with a simpler query if we couldn't find anything
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    
                    #if DEBUG
                    print("🔁 Retrying search (attempt \(self.retryCount))")
                    #endif
                    
                    self.retryAppleMusicSearch(title: title, artist: artist)
                } else {
                    await MainActor.run {
                        self.finishArtworkLoading(success: false)
                    }
                }
            } catch {
                #if DEBUG
                print("❌ Error fetching artwork: \(error.localizedDescription)")
                #endif
                
                // Retry with a simpler query if we hit an error
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    
                    #if DEBUG
                    print("🔁 Retrying after error (attempt \(self.retryCount))")
                    #endif
                    
                    self.retryAppleMusicSearch(title: title, artist: artist)
                } else {
                    await MainActor.run {
                        self.finishArtworkLoading(success: false)
                    }
                }
            }
        }
    }
    
    private func retryAppleMusicSearch(title: String, artist: String) {
        // Simpler query for retry
        let cacheKey = "\(title)-\(artist)"
        
        Task {
            do {
                // Try with just the title for broader results
                let simpleQuery = title
                
                #if DEBUG
                print("🔄 Retrying search with simpler query: \(simpleQuery)")
                #endif
                
                var request = MusicCatalogSearchRequest(term: simpleQuery, types: [Song.self])
                request.limit = 10
                
                let response = try await request.response()
                
                // Look for a likely match
                let possibleMatches = response.songs.filter { song in
                    let titleMatch = song.title.lowercased().contains(title.lowercased())
                    let artistMatch = song.artistName.lowercased().contains(artist.lowercased())
                    return (titleMatch && artistMatch) || titleMatch
                }
                
                if let matchingSong = possibleMatches.first(where: { $0.artwork != nil }) ??
                                     response.songs.first(where: { $0.artwork != nil }),
                   let artworkUrl = matchingSong.artwork?.url(width: 300, height: 300) {
                    
                    #if DEBUG
                    print("🖼️ Found artwork on retry: \(artworkUrl)")
                    #endif
                    
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
                #if DEBUG
                print("❌ Retry error: \(error.localizedDescription)")
                #endif
                
                await MainActor.run {
                    self.finishArtworkLoading(success: false)
                }
            }
        }
    }
    
    private func finishArtworkLoading(success: Bool) {
        self.isLoadingArtwork = false
        
        #if DEBUG
        print("🔍 Artwork loading complete - success: \(success)")
        #endif
    }
    
    // MARK: - Progress Timer
    private func setupProgressTimer() {
        // Clear existing timer
        progressTimer?.invalidate()
        progressTimer = nil
        
        // Only set up timer if playing
        guard isPlaying,
              let song = currentSong,
              song.playbackDuration > 0 else {
            return
        }
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let song = self.currentSong else { return }
            
            let currentPlaybackTime = self.musicPlayer.currentPlaybackTime
            self.playbackProgress = min(currentPlaybackTime / song.playbackDuration, 1.0)
        }
    }
    
    // MARK: - Player Controls
    func togglePlayPause() {
        #if DEBUG
        print("⏯️ Toggle play/pause requested")
        #endif
        
        if isPlaying {
            musicPlayer.pause()
        } else {
            musicPlayer.play()
        }
        
        // Mark the time of this manual action
        lastManualAction = Date()
    }
    
    func nextTrack() {
        #if DEBUG
        print("⏭️ Next track requested")
        #endif
        
        musicPlayer.skipToNextItem()
        
        // Mark the time of this manual action
        lastManualAction = Date()
    }
    
    func previousTrack() {
        #if DEBUG
        print("⏮️ Previous track requested")
        #endif
        
        musicPlayer.skipToPreviousItem()
        
        // Mark the time of this manual action
        lastManualAction = Date()
    }
    
    // Limit cache size periodically
    private func cleanupCache() {
        if artworkCache.count > 50 {
            // Keep just the 25 most recent items
            let sortedKeys = artworkCache.keys.sorted()
            let keysToRemove = sortedKeys.prefix(sortedKeys.count - 25)
            keysToRemove.forEach { artworkCache.removeValue(forKey: $0) }
        }
    }
    
    deinit {
        progressTimer?.invalidate()
        musicPlayer.endGeneratingPlaybackNotifications()
        artworkTask?.cancel()
    }
}
