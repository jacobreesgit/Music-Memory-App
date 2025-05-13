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
    
    private var cancellables = Set<AnyCancellable>()
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var progressTimer: Timer?
    private var artworkTask: Task<Void, Never>?
    
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
            self.currentSong = self.musicPlayer.nowPlayingItem
            self.fetchedArtwork = nil  // Reset fetched artwork
            
            // Try to fetch artwork if local artwork isn't available
            if self.currentSong?.artwork == nil {
                self.fetchArtworkForCurrentSong()
            }
            
            // Reset progress
            self.playbackProgress = 0.0
            self.setupProgressTimer()
        }
    }
    
    // Method to fetch artwork from Apple Music
    private func fetchArtworkForCurrentSong() {
        // Cancel any previous task
        artworkTask?.cancel()
        
        // Only proceed if we have song details
        guard let songTitle = currentSong?.title,
              let artistName = currentSong?.artist else {
            return
        }
        
        // Create search query from song details
        let query = "\(songTitle) \(artistName)"
        
        // Start a new task to search for the song
        artworkTask = Task {
            do {
                // Check if Apple Music is authorized
                if MusicAuthorization.currentStatus != .authorized {
                    // We can't fetch artwork without authorization
                    return
                }
                
                // Create search request
                var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
                request.limit = 5  // Limit results to improve performance
                
                // Send request
                let response = try await request.response()
                
                // Find first matching song with artwork
                if let firstSong = response.songs.first,
                   let artworkUrl = firstSong.artwork?.url(width: 200, height: 200) {
                    
                    // Download artwork image
                    let (data, _) = try await URLSession.shared.data(from: artworkUrl)
                    let image = UIImage(data: data)
                    
                    // Update UI on main thread
                    await MainActor.run {
                        self.fetchedArtwork = image
                    }
                }
            } catch {
                print("Error fetching artwork: \(error.localizedDescription)")
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
    
    deinit {
        progressTimer?.invalidate()
        musicPlayer.endGeneratingPlaybackNotifications()
        artworkTask?.cancel()
    }
}
