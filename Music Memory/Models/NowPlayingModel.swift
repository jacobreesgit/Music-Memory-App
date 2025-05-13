// NowPlayingModel.swift - With stronger artwork validation
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
    @Published var artworkSource: ArtworkSource = .none
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var progressTimer: Timer?
    private var artworkTask: Task<Void, Never>?
    private var artworkCache: [String: UIImage] = [:]
    private var previousSongID: MPMediaEntityPersistentID?
    
    // Defines where artwork came from (for debugging)
    enum ArtworkSource: String {
        case local = "local"
        case fetched = "fetched"
        case none = "none"
    }
    
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
        DispatchQueue.main.async {
            // Check if song actually changed
            let newSong = self.musicPlayer.nowPlayingItem
            let newSongID = newSong?.persistentID
            
            // Clear current artwork and set loading state
            if newSongID != self.previousSongID {
                self.artworkImage = nil
                self.isLoadingArtwork = true
                self.artworkSource = .none
                self.previousSongID = newSongID
            }
            
            // Set the new song
            self.currentSong = newSong
            
            // Reset progress
            self.playbackProgress = 0.0
            self.setupProgressTimer()
            
            // Handle artwork
            self.handleArtworkForCurrentSong()
        }
    }
    
    private func updatePlaybackState() {
        DispatchQueue.main.async {
            self.isPlaying = self.musicPlayer.playbackState == .playing
            self.setupProgressTimer()
        }
    }
    
    // MARK: - Artwork Handling
    private func handleArtworkForCurrentSong() {
        guard let song = currentSong else {
            finishArtworkLoading(source: .none)
            return
        }
        
        // Check if song is actually in the local library - true local songs should have storePersistentID = 0
        // This is a heuristic that might help identify Apple Music streaming tracks
        let isLikelyStreamedSong = song.isCloudItem || song.assetURL == nil
        
        #if DEBUG
        print("📱 Song source check: cloudItem=\(song.isCloudItem), hasAssetURL=\(song.assetURL != nil)")
        #endif
        
        // Add extra validation for artwork
        if let localArtwork = song.artwork {
            let bounds = localArtwork.bounds
            
            #if DEBUG
            print("🔎 Artwork bounds: \(bounds.width)x\(bounds.height)")
            #endif
            
            // Only consider valid if:
            // 1. Has non-zero bounds
            // 2. Actually produces an image
            // 3. NOT likely a streaming track
            if bounds.width > 10 && bounds.height > 10 && !isLikelyStreamedSong,
               let image = localArtwork.image(at: CGSize(width: 300, height: 300)) {
                // We have genuine local artwork with dimensions and that produces an image
                self.artworkImage = image
                finishArtworkLoading(source: .local)
                
                #if DEBUG
                print("✅ Valid local artwork confirmed: \(bounds.width)x\(bounds.height)")
                #endif
                
                return
            } else {
                #if DEBUG
                if bounds.width > 0 && bounds.height > 0 {
                    print("⚠️ Artwork has dimensions but failed validation: \(bounds.width)x\(bounds.height), likely streamed: \(isLikelyStreamedSong)")
                } else {
                    print("⚠️ Empty artwork reference with zero dimensions: \(bounds.width)x\(bounds.height)")
                }
                #endif
            }
        }
        
        // No valid local artwork, try Apple Music
        if let title = song.title, let artist = song.artist {
            fetchAppleMusicArtwork(title: title, artist: artist)
        } else {
            finishArtworkLoading(source: .none)
        }
    }
    
    private func fetchAppleMusicArtwork(title: String, artist: String) {
        // Cancel any previous task
        artworkTask?.cancel()
        
        // Create a cache key
        let cacheKey = "\(title)-\(artist)"
        
        // Check cache first
        if let cachedImage = artworkCache[cacheKey] {
            self.artworkImage = cachedImage
            finishArtworkLoading(source: .fetched)
            
            #if DEBUG
            print("🖼️ Using cached artwork for: \(cacheKey)")
            #endif
            
            return
        }
        
        // Create a new task to search for the song, but only if authorized
        if MusicAuthorization.currentStatus != .authorized {
            finishArtworkLoading(source: .none)
            
            #if DEBUG
            print("⚠️ Not authorized for Apple Music API")
            #endif
            
            return
        }
        
        artworkTask = Task {
            do {
                let query = "\"\(title)\" \"\(artist)\""
                
                #if DEBUG
                print("🔍 Searching Apple Music for: \(query)")
                #endif
                
                var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
                request.limit = 5
                
                let response = try await request.response()
                
                // Find a song with artwork
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
                            self.finishArtworkLoading(source: .fetched)
                        }
                        return
                    }
                } else {
                    #if DEBUG
                    print("⚠️ No artwork found in Apple Music for: \(query)")
                    #endif
                }
                
                // If we get here, we didn't find artwork
                await MainActor.run {
                    self.finishArtworkLoading(source: .none)
                }
            } catch {
                #if DEBUG
                print("❌ Error fetching artwork: \(error.localizedDescription)")
                #endif
                
                await MainActor.run {
                    self.finishArtworkLoading(source: .none)
                }
            }
        }
    }
    
    private func finishArtworkLoading(source: ArtworkSource) {
        self.isLoadingArtwork = false
        self.artworkSource = source
        
        #if DEBUG
        print("🔍 Artwork loading complete - source: \(source.rawValue)")
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
    
    deinit {
        progressTimer?.invalidate()
        musicPlayer.endGeneratingPlaybackNotifications()
        artworkTask?.cancel()
    }
}
