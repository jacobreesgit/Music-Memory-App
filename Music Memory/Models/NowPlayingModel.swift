//
//  NowPlayingModel.swift
//  Music Memory
//
//  Created on 13/05/2025.
//

import MediaPlayer
import Combine

class NowPlayingModel: ObservableObject {
    @Published var currentSong: MPMediaItem?
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var progressTimer: Timer?
    
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
            
            // Reset progress
            self.playbackProgress = 0.0
            self.setupProgressTimer()
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
        guard isPlaying, currentSong != nil else { return }
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let song = self.currentSong else { return }
            
            // Get playback time - no need for optional binding here since it's not optional
            let currentPlaybackTime = self.musicPlayer.currentPlaybackTime
            if song.playbackDuration > 0 {
                self.playbackProgress = min(currentPlaybackTime / song.playbackDuration, 1.0)
            } else {
                // Just increment as a fallback
                self.playbackProgress = min(self.playbackProgress + 0.01, 1.0)
            }
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
    }
}
