//
//  StatsCarouselSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 12/05/2025.
//

import SwiftUI
import MediaPlayer

struct StatsCarouselSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var selectedStatCard = 0
    @State private var carouselTimer: Timer?
    
    var body: some View {
        let statCards = getStatCards()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Your Music Summary")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            // Carousel with infinite scrolling
            TabView(selection: $selectedStatCard) {
                ForEach(Array(statCards.enumerated()), id: \.element.id) { index, card in
                    card
                        .tag(index)
                }
            }
            .frame(height: 140)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.5), value: selectedStatCard)
            .onChange(of: selectedStatCard) { newValue in
                // Handle infinite scrolling using modulo
                withAnimation(.easeInOut(duration: 0.5)) {
                    selectedStatCard = (newValue + statCards.count) % statCards.count
                }
                resetCarouselTimer()
            }
            
            // Page indicator beneath the box
            HStack(spacing: 8) {
                ForEach(0..<statCards.count, id: \.self) { index in
                    Circle()
                        .fill(index == selectedStatCard ? AppStyles.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear {
            startCarouselTimer()
        }
        .onDisappear {
            stopCarouselTimer()
        }
    }
    
    // Helper function to get stats cards data
    private func getStatCards() -> [StatCarouselCard] {
        var cards: [StatCarouselCard] = []
        
        // Card 1: Total listening time (impressive stat)
        cards.append(StatCarouselCard(
            id: "listening_time",
            title: "You've Listened to",
            value: formattedTotalListeningTime,
            subtitle: "of music - that's impressive dedication!",
            icon: "clock.fill",
            color: AppStyles.accentColor
        ))
        
        // Card 2: Most played song (impressive stat)
        if let topSong = musicLibrary.filteredSongs.first {
            cards.append(StatCarouselCard(
                id: "top_song_plays",
                title: "Your Top Song",
                value: "\(topSong.playCount)",
                subtitle: "plays of \"\(topSong.title ?? "Unknown")\"",
                icon: "star.fill",
                color: .orange
            ))
        }
        
        // Card 3: Library size
        cards.append(StatCarouselCard(
            id: "library_size",
            title: "Your Music Library",
            value: "\(musicLibrary.songs.count)",
            subtitle: "songs strong and growing",
            icon: "music.note.list",
            color: .blue
        ))
        
        // Card 4: Total plays
        cards.append(StatCarouselCard(
            id: "total_plays",
            title: "Total Plays",
            value: "\(totalPlays)",
            subtitle: "tracks played across your library",
            icon: "play.circle.fill",
            color: .green
        ))
        
        // Card 5: Artist diversity (impressive stat)
        cards.append(StatCarouselCard(
            id: "artists",
            title: "Musical Diversity",
            value: "\(musicLibrary.artists.count)",
            subtitle: "different artists in your collection",
            icon: "person.3.fill",
            color: .purple
        ))
        
        // Card 6: Listening style
        let style = getListeningStyle()
        cards.append(StatCarouselCard(
            id: "listening_style",
            title: "Listening Style",
            value: style.label,
            subtitle: style.description,
            icon: "repeat",
            color: .red
        ))
        
        // Card 7: Albums owned
        if !musicLibrary.albums.isEmpty {
            cards.append(StatCarouselCard(
                id: "albums",
                title: "Album Collection",
                value: "\(musicLibrary.albums.count)",
                subtitle: "complete albums in your library",
                icon: "square.stack",
                color: .teal
            ))
        }
        
        // Card 8: Genre variety
        if !musicLibrary.genres.isEmpty {
            cards.append(StatCarouselCard(
                id: "genres",
                title: "Genre Explorer",
                value: "\(musicLibrary.genres.count)",
                subtitle: "different genres enjoyed",
                icon: "music.note.list",
                color: .brown
            ))
        }
        
        return cards
    }
    
    // MARK: - Carousel Timer
    
    // Carousel timer management
    func startCarouselTimer() {
        stopCarouselTimer()
        carouselTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [self] _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                selectedStatCard = (selectedStatCard + 1) % getStatCards().count
            }
        }
    }
    
    func stopCarouselTimer() {
        carouselTimer?.invalidate()
        carouselTimer = nil
    }
    
    func resetCarouselTimer() {
        stopCarouselTimer()
        startCarouselTimer()
    }
    
    // MARK: - Data Calculations
    
    // Total listening time
    private var totalListeningTimeSeconds: TimeInterval {
        var total: TimeInterval = 0
        for song in musicLibrary.songs {
            total += song.playbackDuration * Double(song.playCount)
        }
        return total
    }
    
    private var formattedTotalListeningTime: String {
        let totalSeconds = Int(totalListeningTimeSeconds)
        let hours = totalSeconds / 3600
        let days = hours / 24
        
        if days > 365 {
            let years = days / 365
            return "\(years) years"
        } else if days > 30 {
            let months = days / 30
            return "\(months) months"
        } else if days > 0 {
            return "\(days) days"
        } else {
            return "\(hours) hours"
        }
    }
    
    // Total play count
    private var totalPlays: Int {
        musicLibrary.songs.reduce(0) { $0 + $1.playCount }
    }
    
    // Listening style analysis
    private func getListeningStyle() -> (label: String, description: String) {
        let playedSongs = musicLibrary.songs.filter { $0.playCount > 0 }
        if playedSongs.isEmpty { return (label: "Unknown", description: "Not enough data") }
        
        let totalPlays = playedSongs.reduce(0) { $0 + $1.playCount }
        let avgPlaysPerSong = Double(totalPlays) / Double(playedSongs.count)
        
        let repeatScore = min(1.0, log(avgPlaysPerSong) / log(20.0))
        
        if repeatScore < 0.3 {
            return (label: "Explorer", description: "You enjoy discovering new music")
        } else if repeatScore < 0.6 {
            return (label: "Balanced", description: "Mix of favorites and new music")
        } else {
            return (label: "Repeater", description: "You love revisiting favorites")
        }
    }
}

/// Carousel Card View
struct StatCarouselCard: View, Identifiable {
    let id: String
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}
