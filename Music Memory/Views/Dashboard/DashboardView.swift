//
//  DashboardView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//  Enhanced with auto-carousel and improved layout
//

import SwiftUI
import MediaPlayer
import Charts

struct DashboardView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var refreshID = UUID()
    @State private var selectedStatCard = 0
    @State private var carouselTimer: Timer?
    
    var hasNoData: Bool {
        return musicLibrary.filteredSongs.isEmpty &&
               musicLibrary.filteredAlbums.isEmpty &&
               musicLibrary.filteredArtists.isEmpty &&
               musicLibrary.filteredPlaylists.isEmpty
    }
    
    // MARK: - Computed Properties (moved to struct level)
    
    // Artist contribution properties and methods
    private var artistContribution: [ArtistData] {
        musicLibrary.artists.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private var otherArtistsPercentage: Double {
        let totalPlays = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        let top5Plays = artistContribution.prefix(5).reduce(0) { $0 + $1.totalPlayCount }
        let otherPlays = totalPlays - top5Plays
        
        guard totalPlays > 0, otherPlays > 0 else { return 0 }
        return Double(otherPlays) / Double(totalPlays) * 100.0
    }
    
    private func getArtistPercentage(for artist: ArtistData) -> Int {
        let totalPlays = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        guard totalPlays > 0 else { return 0 }
        
        return Int((Double(artist.totalPlayCount) / Double(totalPlays) * 100).rounded())
    }
    
    private func getPercentageWidth(for index: Int, in totalWidth: CGFloat) -> CGFloat {
        guard index < artistContribution.count, totalWidth > 0 else { return 0 }
        
        let percentage = getArtistPercentage(for: artistContribution[index])
        return totalWidth * CGFloat(percentage) / 100.0
    }
    
    private func getArtistVariety() -> (label: String, description: String) {
        let topArtist = musicLibrary.artists.max(by: { $0.totalPlayCount < $1.totalPlayCount })
        let totalPlays = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        
        if let topArtist = topArtist, totalPlays > 0 {
            let percentage = Double(topArtist.totalPlayCount) / Double(totalPlays) * 100
            
            if percentage < 20 {
                return (label: "Very Diverse", description: "You listen to many different artists")
            } else if percentage < 40 {
                return (label: "Diverse", description: "You have a wide range of artists")
            } else if percentage < 60 {
                return (label: "Balanced", description: "Mix of favorites and others")
            } else if percentage < 80 {
                return (label: "Focused", description: "You have clear favorites")
            } else {
                return (label: "Very Focused", description: "You stick to your favorites")
            }
        }
        
        return (label: "Unknown", description: "Not enough data")
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading your music...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    // Invisible anchor for scrolling to top with zero height
                    Text("")
                        .id("top")
                        .frame(height: 0)
                        .padding(0)
                        .opacity(0)
                    
                    if hasNoData {
                        // Show message when there is no data in the library
                        VStack(spacing: 20) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                                .padding(.top, 50)
                            
                            Text("No music data found in your library")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Music with play count information will appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: 32) {
                            // Stats Carousel Section (includes impressive stats)
                            statsCarouselSection
                            
                            // Recently Played Section (renamed from "Your Listening Now")
                            recentlyPlayedSection
                            
                            // Top Artists Section (using TopItemsView)
                            topArtistsSection
                            
                            // Recently Added Section
                            recentlyAddedSection
                            
                            // Top Songs (promoted to higher position)
                            topSongsSection
                            
                            // Top Albums
                            topAlbumsSection
                            
                            // Genre visualization (pie chart only)
                            TopGenresSection()
                            
                            // Artist contribution visualization
                            artistContributionSection
                            
                            // Top Playlists (lower priority)
                            topPlaylistsSection
                        }
                        .padding(.bottom, 20)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .id(refreshID)
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                    startCarouselTimer()
                }
                .onDisappear {
                    stopCarouselTimer()
                }
                .navigationTitle("Dashboard")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    // MARK: - Auto-advancing Stats Carousel
    
    private var statsCarouselSection: some View {
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
    }
    
    // MARK: - Recently Played Section (renamed from "Your Listening Now")
    
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let recentlyPlayed = getRecentlyPlayedSongs(), !recentlyPlayed.isEmpty {
                Text("Recently Played")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        // Regular items
                        ForEach(recentlyPlayed.prefix(5), id: \.persistentID) { song in
                            NavigationLink(destination: SongDetailView(song: song)) {
                                VStack {
                                    // Artwork or placeholder without rank badge
                                    if let artwork = song.artwork {
                                        Image(uiImage: artwork.image(at: CGSize(width: 100, height: 100)) ?? UIImage(systemName: "music.note")!)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(AppStyles.cornerRadius)
                                    } else {
                                        Image(systemName: "music.note")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 80, height: 80)
                                            .padding(10)
                                            .background(AppStyles.secondaryColor)
                                            .cornerRadius(AppStyles.cornerRadius)
                                    }
                                    
                                    // Title
                                    Text(song.title ?? "Unknown")
                                        .font(AppStyles.bodyStyle)
                                        .lineLimit(1)
                                        .foregroundColor(.primary)
                                    
                                    // Subtitle
                                    Text(song.artist ?? "Unknown")
                                        .font(AppStyles.captionStyle)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    // Play count
                                    Text("\(song.playCount ?? 0) plays")
                                        .font(AppStyles.captionStyle)
                                        .foregroundColor(AppStyles.accentColor)
                                }
                                .frame(width: 100)
                            }
                        }
                        
                        // "See All" item
                        NavigationLink(destination: RecentlyPlayedSongsView()) {
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(AppStyles.secondaryColor)
                                        .frame(width: 100, height: 100)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "arrow.right.circle")
                                            .font(.system(size: 30))
                                            .foregroundColor(AppStyles.accentColor)
                                        
                                        Text("See All")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppStyles.accentColor)
                                    }
                                }
                                .frame(width: 100, height: 100)
                                
                                // Empty space to match layout of other items
                                Spacer().frame(height: 18)
                                Spacer().frame(height: 16)
                                Spacer().frame(height: 14)
                            }
                            .frame(width: 100)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Top Artists Section (using TopItemsView)
    
    private var topArtistsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !musicLibrary.filteredArtists.isEmpty {
                Text("Top Artists")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredArtists.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.name },
                    itemSubtitle: { "\($0.songs.count) songs" },
                    itemPlays: { $0.totalPlayCount },
                    iconName: { _ in "music.mic" },
                    destination: { artist, rank in ArtistDetailView(artist: artist, rank: rank) },
                    seeAllDestination: { LibraryView(selectedTab: .constant(1)) }
                )
            }
        }
    }
    
    // MARK: - Recently Added Section
        
    private var recentlyAddedSection: some View {
        let recentlyAdded = getRecentlyAddedSongs()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Recently Added")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // Regular items
                    ForEach(Array(recentlyAdded.prefix(5).enumerated()), id: \.element.persistentID) { index, song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            VStack(spacing: 8) {
                                // Artwork or placeholder
                                if let artwork = song.artwork {
                                    Image(uiImage: artwork.image(at: CGSize(width: 100, height: 100)) ?? UIImage(systemName: "music.note")!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(AppStyles.cornerRadius)
                                } else {
                                    Image(systemName: "music.note")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .padding(10)
                                        .background(AppStyles.secondaryColor)
                                        .cornerRadius(AppStyles.cornerRadius)
                                        .frame(width: 100, height: 100)
                                }
                                
                                // Title
                                Text(song.title ?? "Unknown")
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                
                                // Artist
                                Text(song.artist ?? "Unknown")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                // Days ago
                                Text(daysAgo(song.dateAdded))
                                    .font(.caption2)
                                    .foregroundColor(AppStyles.accentColor)
                            }
                            .frame(width: 100)
                        }
                    }
                    
                    // "See All" item
                    NavigationLink(destination: RecentlyAddedSongsView()) {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(AppStyles.secondaryColor)
                                    .frame(width: 100, height: 100)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "arrow.right.circle")
                                        .font(.system(size: 30))
                                        .foregroundColor(AppStyles.accentColor)
                                    
                                    Text("See All")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppStyles.accentColor)
                                }
                            }
                            .frame(width: 100, height: 100)
                            
                            // Empty space to match layout of other items
                            Spacer().frame(height: 18)
                            Spacer().frame(height: 16)
                            Spacer().frame(height: 14)
                        }
                        .frame(width: 100)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Top Content Sections (Refined)
    
    private var topSongsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !musicLibrary.filteredSongs.isEmpty {
                Text("Top Songs")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredSongs.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.title ?? "Unknown" },
                    itemSubtitle: { $0.artist ?? "Unknown" },
                    itemPlays: { $0.playCount },
                    iconName: { _ in "music.note" },
                    destination: { song, rank in SongDetailView(song: song, rank: rank) },
                    seeAllDestination: { LibraryView(selectedTab: .constant(0)) }
                )
            }
        }
    }
    
    private var topAlbumsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !musicLibrary.filteredAlbums.isEmpty {
                Text("Top Albums")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredAlbums.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.title },
                    itemSubtitle: { $0.artist },
                    itemPlays: { $0.totalPlayCount },
                    iconName: { _ in "square.stack" },
                    destination: { album, rank in AlbumDetailView(album: album, rank: rank) },
                    seeAllDestination: { LibraryView(selectedTab: .constant(2)) }
                )
            }
        }
    }
    
    private var topPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !musicLibrary.filteredPlaylists.isEmpty {
                Text("Top Playlists")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredPlaylists.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.name },
                    itemSubtitle: { "\($0.songs.count) songs" },
                    itemPlays: { $0.totalPlayCount },
                    iconName: { _ in "music.note.list" },
                    destination: { playlist, rank in PlaylistDetailView(playlist: playlist, rank: rank) },
                    seeAllDestination: { LibraryView(selectedTab: .constant(4)) }
                )
            }
        }
    }
    
    // MARK: - Artist Contribution Section
    
    private var artistContributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Artist Contribution")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(getArtistVariety().label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Artist contribution visualization
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(0..<artistContribution.prefix(5).count, id: \.self) { i in
                        Rectangle()
                            .fill(AppStyles.accentColor.opacity(1.0 - (Double(i) * 0.15)))
                            .frame(width: getPercentageWidth(for: i, in: geo.size.width))
                    }
                    
                    if otherArtistsPercentage > 0 {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: geo.size.width * otherArtistsPercentage / 100.0)
                    }
                }
            }
            .frame(height: 30)
            .cornerRadius(AppStyles.cornerRadius)
            .padding(.horizontal)
            
            // Legend
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(artistContribution.prefix(5).enumerated()), id: \.element.id) { index, artist in
                    HStack {
                        Rectangle()
                            .fill(AppStyles.accentColor.opacity(1.0 - (Double(index) * 0.15)))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        
                        Text(artist.name)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(getArtistPercentage(for: artist))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if otherArtistsPercentage > 0 {
                    HStack {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        
                        Text("Other Artists")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(otherArtistsPercentage.rounded()))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    // Stat Cards for Carousel
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
    
    // Carousel timer management
    private func startCarouselTimer() {
        stopCarouselTimer()
        carouselTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [self] _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                selectedStatCard = (selectedStatCard + 1) % getStatCards().count
            }
        }
    }
    
    private func stopCarouselTimer() {
        carouselTimer?.invalidate()
        carouselTimer = nil
    }
    
    private func resetCarouselTimer() {
        stopCarouselTimer()
        startCarouselTimer()
    }
    
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
    
    // Recently played songs
    private func getRecentlyPlayedSongs() -> [MPMediaItem]? {
        let songsWithLastPlayed = musicLibrary.songs.filter { $0.lastPlayedDate != nil }
            .sorted { $0.lastPlayedDate! > $1.lastPlayedDate! }
        
        guard !songsWithLastPlayed.isEmpty else { return nil }
        return Array(songsWithLastPlayed.prefix(5))
    }
    
    // Recently added songs
    private func getRecentlyAddedSongs() -> [MPMediaItem] {
        return musicLibrary.songs.sorted { $0.dateAdded > $1.dateAdded }.prefix(8).map { $0 }
    }
    
    // Time formatting helpers
    private func lastPlayedTimeAgo(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
    
    private func daysAgo(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        let days = Int(timeInterval / 86400)
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks)w ago"
        } else if days < 365 {
            let months = days / 30
            return "\(months)mo ago"
        } else {
            let years = days / 365
            return "\(years)y ago"
        }
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

// MARK: - Stat Carousel Card Model & View

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
