//
//  DashboardView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer
import Charts

struct DashboardView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var refreshID = UUID()
    
    var hasNoData: Bool {
        return musicLibrary.filteredSongs.isEmpty &&
               musicLibrary.filteredAlbums.isEmpty &&
               musicLibrary.filteredArtists.isEmpty &&
               musicLibrary.filteredPlaylists.isEmpty
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
                        VStack(alignment: .leading, spacing: 24) {
                            // Key Stats Summary
                            SummaryStatsSection()
                            
                            // Top Artists (promoted to higher position)
                            topArtistsSection
                            
                            // Top Songs (promoted to higher position)
                            topSongsSection
                            
                            // Top Albums
                            topAlbumsSection
                            
                            // Genre visualization (single, focused section)
                            TopGenresSection()
                            
                            // Recent Discoveries
                            recentDiscoveriesSection
                            
                            // Listening trends visualization
                            listeningTrendsSection
                            
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
                }
            }
        }
    }
    
    // MARK: - Top Content Sections
    
    @ViewBuilder
    private var topArtistsSection: some View {
        if !musicLibrary.filteredArtists.isEmpty {
            VStack(alignment: .leading) {
                Text("Top Artists")
                    .font(AppStyles.headlineStyle)
                    .padding(.horizontal)
                
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredArtists.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.name },
                    itemSubtitle: { "\($0.songs.count) songs" },
                    itemPlays: { $0.totalPlayCount },
                    iconName: { _ in "music.mic" },
                    destination: { artist, rank in ArtistDetailView(artist: artist, rank: rank) }
                )
            }
        }
    }
    
    @ViewBuilder
    private var topSongsSection: some View {
        if !musicLibrary.filteredSongs.isEmpty {
            VStack(alignment: .leading) {
                Text("Top Songs")
                    .font(AppStyles.headlineStyle)
                    .padding(.horizontal)
                
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredSongs.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.title ?? "Unknown" },
                    itemSubtitle: { $0.artist ?? "Unknown" },
                    itemPlays: { $0.playCount },
                    iconName: { _ in "music.note" },
                    destination: { song, rank in SongDetailView(song: song, rank: rank) }
                )
            }
        }
    }
    
    @ViewBuilder
    private var topAlbumsSection: some View {
        if !musicLibrary.filteredAlbums.isEmpty {
            VStack(alignment: .leading) {
                Text("Top Albums")
                    .font(AppStyles.headlineStyle)
                    .padding(.horizontal)
                
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredAlbums.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.title },
                    itemSubtitle: { $0.artist },
                    itemPlays: { $0.totalPlayCount },
                    iconName: { _ in "square.stack" },
                    destination: { album, rank in AlbumDetailView(album: album, rank: rank) }
                )
            }
        }
    }
    
    @ViewBuilder
    private var topPlaylistsSection: some View {
        if !musicLibrary.filteredPlaylists.isEmpty {
            VStack(alignment: .leading) {
                Text("Top Playlists")
                    .font(AppStyles.headlineStyle)
                    .padding(.horizontal)
                
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredPlaylists.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.name },
                    itemSubtitle: { "\($0.songs.count) songs" },
                    itemPlays: { $0.totalPlayCount },
                    iconName: { _ in "music.note.list" },
                    destination: { playlist, rank in PlaylistDetailView(playlist: playlist, rank: rank) }
                )
            }
        }
    }
    
    // MARK: - Recent Discoveries Section
    
    private var recentDiscoveriesSection: some View {
        VStack(alignment: .leading) {
            Text("Recent Discoveries")
                .font(AppStyles.headlineStyle)
                .padding(.horizontal)
            
            let recentDiscoveries = getRecentDiscoveries(limit: 5)
            
            if recentDiscoveries.isEmpty {
                Text("No recent discoveries found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(AppStyles.secondaryColor.opacity(0.3))
                    .cornerRadius(AppStyles.cornerRadius)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentDiscoveries.enumerated()), id: \.element.persistentID) { index, song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            HStack(spacing: 10) {
                                SongRow(song: song)
                                
                                // Play rate indicator
                                VStack(alignment: .trailing) {
                                    Text(String(format: "%.1f", playRateForSong(song)))
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                    Text("plays/day")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if index < recentDiscoveries.count - 1 {
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
                .padding()
                .background(AppStyles.secondaryColor.opacity(0.3))
                .cornerRadius(AppStyles.cornerRadius)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Listening Trends Section
    
    private var listeningTrendsSection: some View {
        VStack(alignment: .leading) {
            Text("Listening Trends")
                .font(AppStyles.headlineStyle)
                .padding(.horizontal)
                
            HStack(spacing: 12) {
                // Favorite era visualization
                StatCard(
                    title: "Favorite Era",
                    value: getFavoriteEra().era,
                    subtitle: "\(getFavoriteEra().plays) plays",
                    icon: "clock.arrow.circlepath",
                    color: AppStyles.accentColor
                )
                
                // Repeat listening score
                StatCard(
                    title: "Listening Style",
                    value: getListeningStyle().label,
                    subtitle: getListeningStyle().description,
                    icon: "repeat",
                    color: .blue
                )
            }
            .padding(.horizontal)
            
            // Album Completion Rate
            HStack(spacing: 12) {
                // Artist variety score
                StatCard(
                    title: "Artist Variety",
                    value: getArtistVariety().label,
                    subtitle: getArtistVariety().description,
                    icon: "person.3",
                    color: .green
                )
                
                // Listening consistency
                StatCard(
                    title: "Listening Pattern",
                    value: getListeningPattern().label,
                    subtitle: getListeningPattern().description,
                    icon: "waveform",
                    color: .orange
                )
            }
            .padding(.horizontal)
            
            // Artist contribution visualization
            artistContributionSection
        }
    }
    
    // Artist contribution visualization
    private var artistContributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Artist Contribution")
                    .font(.subheadline)
                    .foregroundColor(AppStyles.accentColor)
                
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
        .padding(.vertical, 12)
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func getRecentDiscoveries(limit: Int) -> [MPMediaItem] {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        
        return musicLibrary.songs
            .filter { song in
                let dateAdded = song.dateAdded
                guard dateAdded > threeMonthsAgo, song.playCount > 5 else { return false }
                return true
            }
            .sorted { playRateForSong($0) > playRateForSong($1) }
            .prefix(limit)
            .map { $0 }
    }
    
    private func playRateForSong(_ song: MPMediaItem) -> Double {
        let dateAdded = song.dateAdded
        let daysSinceAdded = Date().timeIntervalSince(dateAdded) / (60 * 60 * 24)
        return Double(song.playCount) / max(1, daysSinceAdded)
    }
    
    private func getFavoriteEra() -> (era: String, plays: Int) {
        var decadeCounts: [String: Int] = [:]
        
        for song in musicLibrary.songs where song.playCount > 0 {
            if let releaseDate = song.releaseDate {
                let year = Calendar.current.component(.year, from: releaseDate)
                let decade = "\(year / 10 * 10)s"
                decadeCounts[decade, default: 0] += song.playCount
            }
        }
        
        if let topDecade = decadeCounts.max(by: { $0.value < $1.value }) {
            return (era: topDecade.key, plays: topDecade.value)
        }
        
        return (era: "Unknown", plays: 0)
    }
    
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
    
    private func getListeningPattern() -> (label: String, description: String) {
        // Calculate album completion rate
        var totalAlbumSongs = 0
        var totalPlayedAlbumSongs = 0
        
        for album in musicLibrary.albums {
            let albumSongs = album.songs.count
            let playedSongs = album.songs.filter { $0.playCount > 0 }.count
            
            totalAlbumSongs += albumSongs
            totalPlayedAlbumSongs += playedSongs
        }
        
        guard totalAlbumSongs > 0 else { return (label: "Unknown", description: "Not enough data") }
        
        let completionRate = Double(totalPlayedAlbumSongs) / Double(totalAlbumSongs)
        
        if completionRate < 0.3 {
            return (label: "Cherry-Picker", description: "You listen to specific tracks")
        } else if completionRate < 0.7 {
            return (label: "Browser", description: "You sample from many albums")
        } else {
            return (label: "Album Listener", description: "You enjoy complete albums")
        }
    }
    
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
}
