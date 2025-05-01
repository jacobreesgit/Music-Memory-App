//
//  ListeningAnalyticsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer
import Charts

struct ListeningAnalyticsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Top section with basic stats summary
                StatsOverviewCard()
                .padding(.horizontal)
                
                // Tab selection for different analytics
                AnalyticsTabView(selectedTab: $selectedTab)
                    .padding(.horizontal)
                
                // Tab content
                VStack {
                    switch selectedTab {
                    case 0:
                        GenreAnalyticsView()
                    case 1:
                        TimeAnalyticsView()
                    case 2:
                        ListeningPatternsView()
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Listening Analytics")
    }
}

// MARK: - Stats Overview Card

struct StatsOverviewCard: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Music Overview")
                .font(AppStyles.headlineStyle)
                .foregroundColor(AppStyles.accentColor)
            
            HStack(spacing: 0) {
                // Total Songs
                VStack {
                    Text("\(musicLibrary.songs.count)")
                        .font(.system(size: 24, weight: .bold))
                    Text("Songs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                // Total Artists
                VStack {
                    Text("\(musicLibrary.artists.count)")
                        .font(.system(size: 24, weight: .bold))
                    Text("Artists")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                // Total Genres
                VStack {
                    Text("\(musicLibrary.genres.count)")
                        .font(.system(size: 24, weight: .bold))
                    Text("Genres")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            // Updated top artist section with matching chevron style
            if let topArtist = musicLibrary.artists.first {
                NavigationLink(destination: ArtistDetailView(artist: topArtist)) {
                    HStack {
                        // Use existing ArtistRow without its trailing content
                        HStack(spacing: AppStyles.smallPadding) {
                            // Artwork or placeholder
                            if let artwork = topArtist.artwork {
                                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "music.mic")!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(AppStyles.cornerRadius)
                            } else {
                                // Fallback to icon if no artwork is available
                                ZStack {
                                    Circle()
                                        .fill(AppStyles.secondaryColor)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "music.mic")
                                        .font(.system(size: 24))
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Artist name (vertically centered)
                            Text(topArtist.name)
                                .font(AppStyles.bodyStyle)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Play count with "plays" text
                            Text("\(topArtist.totalPlayCount) plays")
                                .font(AppStyles.playCountStyle)
                                .foregroundColor(AppStyles.accentColor)
                        }
                        
                        // Add custom chevron with proper spacing
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color.secondary.opacity(0.5))
                            .padding(.leading, 8)
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
    }
}

// MARK: - Analytics Tab View

struct AnalyticsTabView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tabTitle(for: index))
                            .font(.headline)
                            .foregroundColor(selectedTab == index ? AppStyles.accentColor : .secondary)
                            .fontWeight(selectedTab == index ? .bold : .regular)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                }
            }
        }
        .overlay(
            // Moving underline indicator
            GeometryReader { geo in
                let tabWidth = geo.size.width / 3
                Rectangle()
                    .fill(AppStyles.accentColor)
                    .frame(width: tabWidth - 20, height: 2)
                    .offset(x: CGFloat(selectedTab) * tabWidth + 10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
            .frame(height: 2)
            , alignment: .bottom
        )
        .padding(.top, 8)
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Genres"
        case 1: return "Time"
        case 2: return "Patterns"
        default: return ""
        }
    }
}

// MARK: - Genre Analytics View

struct GenreAnalyticsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Genre Distribution")
                .sectionHeaderStyle()
            
            // Genre chart
            if !topGenres.isEmpty {
                Chart {
                    ForEach(topGenres.prefix(8), id: \.name) { genre in
                        BarMark(
                            x: .value("Plays", genre.totalPlayCount),
                            y: .value("Genre", genre.name)
                        )
                        .foregroundStyle(AppStyles.accentColor.gradient)
                        .annotation(position: .trailing) {
                            Text("\(genre.totalPlayCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .padding()
                .background(AppStyles.secondaryColor.opacity(0.3))
                .cornerRadius(AppStyles.cornerRadius)
            }
            
            // Genre diversity metrics
            VStack(alignment: .leading, spacing: 12) {
                Text("Genre Diversity")
                    .font(.subheadline)
                    .foregroundColor(AppStyles.accentColor)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Total Genres")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(musicLibrary.genres.count)")
                            .font(.title3)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Top Genre")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let topGenre = topGenres.first {
                            Text(topGenre.name)
                                .font(.title3)
                                .lineLimit(1)
                        }
                    }
                }
                
                // Genre diversity bar
                VStack(alignment: .leading, spacing: 4) {
                    Text("Genre Focus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            // Fill based on how much the top genre dominates
                            Rectangle()
                                .fill(AppStyles.accentColor)
                                .frame(width: topGenreDominance * geometry.size.width, height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 12)
                    
                    HStack {
                        Text("Diverse")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Focused")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(AppStyles.secondaryColor.opacity(0.3))
            .cornerRadius(AppStyles.cornerRadius)
        }
    }
    
    // Top genres sorted by play count
    private var topGenres: [GenreData] {
        musicLibrary.genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Calculation for how much the top genre dominates (0-1)
    private var topGenreDominance: Double {
        guard let topGenre = topGenres.first, !musicLibrary.genres.isEmpty else {
            return 0.0
        }
        
        let totalPlays = musicLibrary.genres.reduce(0) { $0 + $1.totalPlayCount }
        let proportion = Double(topGenre.totalPlayCount) / Double(totalPlays)
        
        // Scale for better visualization (0.1 to 0.9 range)
        return 0.1 + (proportion * 0.8)
    }
}

// MARK: - Time Analytics View

struct TimeAnalyticsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Listening Duration")
                .sectionHeaderStyle()
            
            // Total listening time card
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Listening Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formattedTotalListeningTime)
                        .font(.system(size: 24, weight: .bold))
                }
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 36))
                    .foregroundColor(AppStyles.accentColor.opacity(0.7))
            }
            .padding()
            .background(AppStyles.secondaryColor.opacity(0.3))
            .cornerRadius(AppStyles.cornerRadius)
            
            // Era distribution chart
            Text("Music by Decade")
                .sectionHeaderStyle()
                .padding(.top, 8)
            
            if !decadeCounts.isEmpty {
                Chart {
                    ForEach(Array(decadeCounts.sorted(by: { $0.key < $1.key })), id: \.key) { decade, count in
                        BarMark(
                            x: .value("Decade", decade),
                            y: .value("Plays", count)
                        )
                        .foregroundStyle(AppStyles.accentColor.gradient)
                    }
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .padding()
                .background(AppStyles.secondaryColor.opacity(0.3))
                .cornerRadius(AppStyles.cornerRadius)
            } else {
                Text("Not enough release date information available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppStyles.secondaryColor.opacity(0.3))
                    .cornerRadius(AppStyles.cornerRadius)
            }
            
            // Song length distribution
            VStack(alignment: .leading, spacing: 12) {
                Text("Song Length Distribution")
                    .font(.subheadline)
                    .foregroundColor(AppStyles.accentColor)
                
                if !songLengthDistribution.isEmpty {
                    Chart {
                        ForEach(songLengthDistribution, id: \.range) { item in
                            BarMark(
                                x: .value("Range", item.range),
                                y: .value("Count", item.count)
                            )
                            .foregroundStyle(AppStyles.accentColor.gradient)
                        }
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.caption)
                        }
                    }
                }
                
                // Length stats
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Shortest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(shortestSongInfo)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .trailing) {
                        Text("Longest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(longestSongInfo)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
            .background(AppStyles.secondaryColor.opacity(0.3))
            .cornerRadius(AppStyles.cornerRadius)
        }
    }
    
    // Calculate total listening time
    private var totalListeningTimeSeconds: TimeInterval {
        var total: TimeInterval = 0
        
        for song in musicLibrary.songs {
            total += song.playbackDuration * Double(song.playCount)
        }
        
        return total
    }
    
    // Format the total listening time nicely
    private var formattedTotalListeningTime: String {
        let totalSeconds = Int(totalListeningTimeSeconds)
        let hours = totalSeconds / 3600
        
        if hours > 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return "\(days) days, \(remainingHours) hours"
        } else {
            let minutes = (totalSeconds % 3600) / 60
            return "\(hours) hours, \(minutes) minutes"
        }
    }
    
    // Decade distribution
    private var decadeCounts: [String: Int] {
        var counts: [String: Int] = [:]
        
        for song in musicLibrary.songs where song.playCount > 0 {
            if let releaseDate = song.releaseDate {
                let year = Calendar.current.component(.year, from: releaseDate)
                let decade = "\(year / 10 * 10)s"
                counts[decade, default: 0] += song.playCount
            }
        }
        
        return counts
    }
    
    // Song length distribution data
    private var songLengthDistribution: [SongLengthRange] {
        var ranges: [String: Int] = [
            "< 2 min": 0,
            "2-3 min": 0,
            "3-4 min": 0,
            "4-5 min": 0,
            "5+ min": 0
        ]
        
        for song in musicLibrary.songs {
            let minutes = song.playbackDuration / 60
            
            if minutes < 2 {
                ranges["< 2 min"]! += 1
            } else if minutes < 3 {
                ranges["2-3 min"]! += 1
            } else if minutes < 4 {
                ranges["3-4 min"]! += 1
            } else if minutes < 5 {
                ranges["4-5 min"]! += 1
            } else {
                ranges["5+ min"]! += 1
            }
        }
        
        return [
            SongLengthRange(range: "< 2 min", count: ranges["< 2 min"] ?? 0),
            SongLengthRange(range: "2-3 min", count: ranges["2-3 min"] ?? 0),
            SongLengthRange(range: "3-4 min", count: ranges["3-4 min"] ?? 0),
            SongLengthRange(range: "4-5 min", count: ranges["4-5 min"] ?? 0),
            SongLengthRange(range: "5+ min", count: ranges["5+ min"] ?? 0)
        ]
    }
    
    // Shortest song
    private var shortestSongInfo: String {
        if let shortestSong = musicLibrary.songs.min(by: { $0.playbackDuration < $1.playbackDuration }) {
            let minutes = Int(shortestSong.playbackDuration / 60)
            let seconds = Int(shortestSong.playbackDuration.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        
        return "N/A"
    }
    
    // Longest song
    private var longestSongInfo: String {
        if let longestSong = musicLibrary.songs.max(by: { $0.playbackDuration < $1.playbackDuration }) {
            let minutes = Int(longestSong.playbackDuration / 60)
            let seconds = Int(longestSong.playbackDuration.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        
        return "N/A"
    }
    
    // Helper struct for song length distribution
    struct SongLengthRange: Identifiable {
        let id = UUID()
        let range: String
        let count: Int
    }
}


struct ListeningPatternsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Listening Habits")
                .sectionHeaderStyle()
            
            // Repeat metrics
            VStack(alignment: .leading, spacing: 12) {
                Text("Repeat Listening")
                    .font(.subheadline)
                    .foregroundColor(AppStyles.accentColor)
                
                HStack(spacing: 20) {
                    // Most played song
                    VStack(alignment: .leading) {
                        Text("Most Played Song")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let topSong = musicLibrary.songs.sorted(by: { $0.playCount > $1.playCount }).first {
                            Text(topSong.title ?? "Unknown")
                                .font(.subheadline)
                                .lineLimit(1)
                            Text("\(topSong.playCount) plays")
                                .font(.caption)
                                .foregroundColor(AppStyles.accentColor)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Repeat listening score
                    VStack(alignment: .trailing) {
                        Text("Repeat Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(repeatListeningScore * 100))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .lineLimit(1)
                        Text(repeatListeningDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
            .background(AppStyles.secondaryColor.opacity(0.3))
            .cornerRadius(AppStyles.cornerRadius)
            
            // Listening variety
            VStack(alignment: .leading, spacing: 12) {
                Text("Listening Variety")
                    .font(.subheadline)
                    .foregroundColor(AppStyles.accentColor)
                
                // Artist variety metrics
                HStack {
                    VStack(alignment: .leading) {
                        Text("Top 5 Artists")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", topArtistPercentage))%")
                            .font(.title3)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Artist Variety")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(artistVarietyDescription)
                            .font(.title3)
                    }
                }
                
                // Artist top 5 vs others visualization - FIXED to properly display percentages
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        // Display top 5 artists proportionally
                        ForEach(0..<5) { i in
                            if i < artistContribution.count {
                                Rectangle()
                                    .fill(AppStyles.accentColor.opacity(1.0 - (Double(i) * 0.15)))
                                    .frame(width: getPercentageWidth(for: i, in: geo.size.width))
                            }
                        }
                        
                        // Other artists - now correctly sized
                        if let otherPercentage = otherArtistsPercentage, otherPercentage > 0 {
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: geo.size.width * otherPercentage / 100.0)
                        }
                    }
                }
                .frame(height: 30)
                .cornerRadius(AppStyles.cornerRadius)
                
                // Artist legend - UPDATED to include percentages
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
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            Text("\(artist.totalPlayCount) plays (\(getArtistPercentage(for: artist))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Other artists - UPDATED to include percentage
                    if let otherPlays = otherArtistsPlayCount, let otherPercentage = otherArtistsPercentage, otherPlays > 0 {
                        HStack {
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 12, height: 12)
                                .cornerRadius(2)
                            
                            Text("Other Artists")
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(otherPlays) plays (\(Int(otherPercentage.rounded()))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(AppStyles.secondaryColor.opacity(0.3))
            .cornerRadius(AppStyles.cornerRadius)
            
            // Album listening patterns
            VStack(alignment: .leading, spacing: 12) {
                Text("Album vs Single Tracks")
                    .font(.subheadline)
                    .foregroundColor(AppStyles.accentColor)
                
                // Album loyalty score visualization
                HStack(spacing: 16) {
                    // Album loyalty score
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 10)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: albumCompletionRate)
                            .stroke(AppStyles.accentColor, lineWidth: 10)
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(albumCompletionRate * 100))%")
                            .font(.system(size: 18, weight: .bold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Album Completion")
                            .font(.subheadline)
                        
                        Text("You tend to \(albumListeningDescription) when listening to albums")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(AppStyles.secondaryColor.opacity(0.3))
            .cornerRadius(AppStyles.cornerRadius)
        }
    }
    
    // NEW: Helper function to calculate percentage for a specific artist
    private func getArtistPercentage(for artist: ArtistData) -> String {
        let totalPlays = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        guard totalPlays > 0 else { return "0" }
        
        let percentage = Double(artist.totalPlayCount) / Double(totalPlays) * 100.0
        return percentage < 10 ? String(format: "%.1f", percentage) : "\(Int(percentage.rounded()))"
    }
    
    // FIXED: Helper function to calculate width based on actual percentage of total plays
    private func getPercentageWidth(for index: Int, in totalWidth: CGFloat) -> CGFloat {
        guard index < artistContribution.count else { return 0 }
        
        let totalPlays = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        guard totalPlays > 0 else { return 0 }
        
        let artistPlays = artistContribution[index].totalPlayCount
        let percentage = Double(artistPlays) / Double(totalPlays) * 100.0
        
        return totalWidth * percentage / 100.0
    }
    
    // Repeat listening score (how many times do you repeat your songs on average)
    private var repeatListeningScore: Double {
        let playedSongs = musicLibrary.songs.filter { $0.playCount > 0 }
        if playedSongs.isEmpty {
            return 0.0
        }
        
        let totalPlays = playedSongs.reduce(0) { $0 + $1.playCount }
        let avgPlaysPerSong = Double(totalPlays) / Double(playedSongs.count)
        
        // Normalize to a 0-1 score (where 1 is high repeat listening)
        // Using log scale to handle outliers
        return min(1.0, log(avgPlaysPerSong) / log(20.0))
    }
    
    // Description of repeat listening habits
    private var repeatListeningDescription: String {
        if repeatListeningScore < 0.3 {
            return "Explorer"
        } else if repeatListeningScore < 0.6 {
            return "Balanced"
        } else {
            return "Repeater"
        }
    }
    
    // Artist contribution (sorted by play count)
    private var artistContribution: [ArtistData] {
        musicLibrary.artists.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Play count from artists outside the top 5
    private var otherArtistsPlayCount: Int? {
        let top5Count = artistContribution.prefix(5).reduce(0) { $0 + $1.totalPlayCount }
        let totalCount = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        let otherCount = totalCount - top5Count
        return otherCount > 0 ? otherCount : nil
    }
    
    // FIXED: Percentage for other artists visualization - now returning actual percentage
    private var otherArtistsPercentage: Double? {
        guard let otherCount = otherArtistsPlayCount else { return nil }
        let totalCount = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        guard totalCount > 0 else { return nil }
        // Return actual percentage rather than proportion
        return Double(otherCount) / Double(totalCount) * 100.0
    }
    
    // Percentage of plays from top 5 artists
    private var topArtistPercentage: Double {
        let totalPlays = musicLibrary.songs.reduce(0) { $0 + $1.playCount }
        if totalPlays == 0 {
            return 0.0
        }
        
        let top5Plays = artistContribution.prefix(5).reduce(0) { $0 + $1.totalPlayCount }
        return Double(top5Plays) / Double(totalPlays) * 100.0
    }
    
    // Description of artist variety
    private var artistVarietyDescription: String {
        if topArtistPercentage < 40 {
            return "Very Diverse"
        } else if topArtistPercentage < 60 {
            return "Balanced"
        } else if topArtistPercentage < 80 {
            return "Focused"
        } else {
            return "Very Focused"
        }
    }
    
    // Album completion rate (how much of albums you listen to on average)
    private var albumCompletionRate: Double {
        var totalAlbumSongs = 0
        var totalPlayedAlbumSongs = 0
        
        for album in musicLibrary.albums {
            let albumSongs = album.songs.count
            let playedSongs = album.songs.filter { $0.playCount > 0 }.count
            
            totalAlbumSongs += albumSongs
            totalPlayedAlbumSongs += playedSongs
        }
        
        if totalAlbumSongs == 0 {
            return 0.0
        }
        
        return Double(totalPlayedAlbumSongs) / Double(totalAlbumSongs)
    }
    
    // Description of album listening habits
    private var albumListeningDescription: String {
        if albumCompletionRate < 0.3 {
            return "cherry-pick specific tracks"
        } else if albumCompletionRate < 0.7 {
            return "listen to selected songs"
        } else {
            return "listen to complete albums"
        }
    }
}
