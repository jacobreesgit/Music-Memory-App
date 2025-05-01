//
//  ListeningTimelineView.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer
import Charts

struct ListeningTimelineView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var selectedTab = 2 // Default to "Year" view
    @State private var selectedDate: Date?
    @State private var cachedData: [Int: TimelineTabData] = [:]
    
    enum TimelineMode: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var id: String { self.rawValue }
    }
    
    var timelineMode: TimelineMode {
        TimelineMode.allCases[selectedTab]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Timeline mode selector with swipeable tabs
            VStack(alignment: .leading, spacing: 8) {
                Text("Listening Timeline")
                    .font(AppStyles.headlineStyle)
                    .foregroundColor(AppStyles.accentColor)
                    .padding(.horizontal)
                
                // Tab bar with underline indicator
                HStack(spacing: 0) {
                    ForEach(Array(TimelineMode.allCases.enumerated()), id: \.element.id) { index, mode in
                        Button(action: {
                            selectedTab = index
                        }) {
                            VStack(spacing: 4) {
                                Text(mode.rawValue)
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
                        let tabWidth = geo.size.width / CGFloat(TimelineMode.allCases.count)
                        Rectangle()
                            .fill(AppStyles.accentColor)
                            .frame(width: tabWidth - 20, height: 2)
                            .offset(x: CGFloat(selectedTab) * tabWidth + 10)
                    }
                    .frame(height: 2)
                    , alignment: .bottom
                )
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: selectedTab)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .padding(.horizontal)
            
            // TabView for swipeable content
            TabView(selection: $selectedTab) {
                ForEach(Array(TimelineMode.allCases.enumerated()), id: \.element.id) { index, mode in
                    timelineContentView(for: mode, tabIndex: index)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(nil, value: selectedTab)
            .onChange(of: selectedTab) { _ in
                // Clear date selection when changing tabs
                selectedDate = nil
            }
        }
        .navigationTitle("Listening Timeline")
        .onAppear {
            // Pre-compute data for the current tab to avoid delay
            if cachedData[selectedTab] == nil {
                cachedData[selectedTab] = generateTimelineData(for: timelineMode)
            }
        }
    }
    
    // Extract each tab's content to a separate function for clarity and performance
    @ViewBuilder
    private func timelineContentView(for mode: TimelineMode, tabIndex: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Get or compute cached data for this tab
                let tabData = cachedData[tabIndex] ?? generateTimelineData(for: mode)
                
                // Timeline chart for the specific mode
                TimelineChartView(
                    timelineMode: mode,
                    selectedDate: $selectedDate,
                    timelineData: tabData.timelineData
                )
                .padding(.horizontal)
                .onAppear {
                    // Cache data if not already cached
                    if cachedData[tabIndex] == nil {
                        cachedData[tabIndex] = tabData
                    }
                }
                
                // Selected date details (if any)
                if let selectedDate = selectedDate {
                    SelectedDateView(
                        date: selectedDate,
                        timelineMode: mode,
                        selectedPeriodSongs: tabData.songsForDate(selectedDate)
                    )
                    .padding(.horizontal)
                }
                
                // Top discoveries - filtered by the selected date if any
                TopDiscoveriesView(
                    timelineMode: mode,
                    selectedDate: selectedDate
                )
                .padding(.horizontal)
                
                ListeningStreakView()
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
    }
    
    // Generate timeline data for a specific mode (for caching)
    private func generateTimelineData(for mode: TimelineMode) -> TimelineTabData {
        // Process song data for the specified time mode
        let calendar = Calendar.current
        let now = Date()
        
        // Filter songs with last played date
        let playedSongs = musicLibrary.songs.filter { song in
            return song.lastPlayedDate != nil && song.playCount > 0
        }
        
        // Group by time period based on selected mode
        var datePlays: [Date: Int] = [:]
        var songsByDate: [Date: [MPMediaItem]] = [:]
        
        for song in playedSongs {
            guard let lastPlayed = song.lastPlayedDate else { continue }
            
            let normalizedDate: Date
            var shouldInclude = false
            
            switch mode {
            case .week:
                // Group by day of week (last 7 days)
                let dayComponent = calendar.dateComponents([.day], from: lastPlayed, to: now)
                if let day = dayComponent.day, day <= 7 {
                    normalizedDate = calendar.startOfDay(for: lastPlayed)
                    shouldInclude = true
                } else {
                    normalizedDate = Date() // Placeholder
                }
                
            case .month:
                // Group by day of month (last 30 days)
                let dayComponent = calendar.dateComponents([.day], from: lastPlayed, to: now)
                if let day = dayComponent.day, day <= 30 {
                    normalizedDate = calendar.startOfDay(for: lastPlayed)
                    shouldInclude = true
                } else {
                    normalizedDate = Date() // Placeholder
                }
                
            case .year:
                // Group by month of year (last 12 months)
                if let month = calendar.dateComponents([.month], from: lastPlayed, to: now).month, month <= 12 {
                    var components = calendar.dateComponents([.year, .month], from: lastPlayed)
                    components.day = 1
                    if let monthStart = calendar.date(from: components) {
                        normalizedDate = monthStart
                        shouldInclude = true
                    } else {
                        normalizedDate = Date() // Placeholder
                    }
                } else {
                    normalizedDate = Date() // Placeholder
                }
            }
            
            if shouldInclude {
                datePlays[normalizedDate, default: 0] += song.playCount
                
                // Group songs by date for quick access later
                if songsByDate[normalizedDate] == nil {
                    songsByDate[normalizedDate] = []
                }
                songsByDate[normalizedDate]?.append(song)
            }
        }
        
        // Convert to chart data points and sort by date
        let timelinePoints = datePlays.map { date, plays in
            TimelineDataPoint(date: date, plays: plays)
        }.sorted { $0.date < $1.date }
        
        return TimelineTabData(timelineData: timelinePoints, songsByDate: songsByDate)
    }
    
    // Data container for a timeline tab
    struct TimelineTabData {
        let timelineData: [TimelineDataPoint]
        let songsByDate: [Date: [MPMediaItem]]
        
        // Helper function to get songs for a specific date
        func songsForDate(_ date: Date) -> [MPMediaItem] {
            // Find the best matching date in our data
            let calendar = Calendar.current
            
            // Look for exact match first
            for (dataDate, songs) in songsByDate {
                if calendar.isDate(dataDate, inSameDayAs: date) {
                    return songs
                }
            }
            
            // Try matching by month if no exact day match
            for (dataDate, songs) in songsByDate {
                if calendar.isDate(dataDate, equalTo: date, toGranularity: .month) {
                    return songs
                }
            }
            
            // Try matching by year if no month match
            for (dataDate, songs) in songsByDate {
                if calendar.isDate(dataDate, equalTo: date, toGranularity: .year) {
                    return songs
                }
            }
            
            return []
        }
    }
    
    // Data point for timeline chart
    struct TimelineDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let plays: Int
    }
}

// MARK: - Timeline Chart View

struct TimelineChartView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let timelineMode: ListeningTimelineView.TimelineMode
    @Binding var selectedDate: Date?
    let timelineData: [ListeningTimelineView.TimelineDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plays Over Time")
                .sectionHeaderStyle()
            
            if !timelineData.isEmpty {
                Chart {
                    ForEach(timelineData) { item in
                        BarMark(
                            x: .value("Date", item.date),
                            y: .value("Plays", item.plays)
                        )
                        .foregroundStyle(AppStyles.accentColor.gradient)
                        // Highlight selected bar if any
                        .opacity(selectedDate == nil || isSameTimePeriod(item.date, selectedDate!) ? 1.0 : 0.3)
                    }
                    
                    if let selected = selectedDate, let selectedDataPoint = timelineData.first(where: { isSameTimePeriod($0.date, selected) }) {
                        RuleMark(
                            x: .value("Selected", selectedDataPoint.date)
                        )
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let xPosition = value.location.x - geometry.frame(in: .local).minX
                                        if let date = proxy.value(atX: xPosition, as: Date.self),
                                           let closestDate = findClosestDate(to: date) {
                                            selectedDate = closestDate
                                        }
                                    }
                            )
                    }
                }
                
                Text("Tap on the chart to select a time period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("Not enough listening history data available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
    }
    
    // Find closest date in our data points to the selected position
    private func findClosestDate(to date: Date) -> Date? {
        guard !timelineData.isEmpty else { return nil }
        
        return timelineData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })?.date
    }
    
    // Check if two dates are in the same time period based on mode
    private func isSameTimePeriod(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        
        switch timelineMode {
        case .week, .month:
            return calendar.isDate(date1, inSameDayAs: date2)
        case .year:
            return calendar.isDate(date1, equalTo: date2, toGranularity: .month)
        }
    }
}

// MARK: - Selected Date View

struct SelectedDateView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let date: Date
    let timelineMode: ListeningTimelineView.TimelineMode
    let selectedPeriodSongs: [MPMediaItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Format date based on selection
            Text(formattedDate)
                .font(.headline)
                .foregroundColor(AppStyles.accentColor)
            
            // Top songs for this period - now uses pre-filtered songs
            if !selectedPeriodSongs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Top Songs")
                        .font(.subheadline)
                        .foregroundColor(AppStyles.accentColor)
                    
                    // Sort songs by play count
                    let topSongs = Array(selectedPeriodSongs.sorted { $0.playCount > $1.playCount }.prefix(3))
                    
                    ForEach(Array(topSongs.enumerated()), id: \.element.persistentID) { index, song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            HStack(spacing: 10) {
                                Text("#\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 30, alignment: .leading)
                                
                                SongRow(song: song)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowSeparator(.hidden)
                    }
                }
            } else {
                Text("No songs played in this period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
    }
    
    // Format the date based on granularity
    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        
        // Check if this is a day, month, or year view
        if calendar.isDate(date, equalTo: now, toGranularity: .day) {
            return "Today"
        } else if calendar.isDate(date, equalTo: calendar.date(byAdding: .day, value: -1, to: now)!, toGranularity: .day) {
            return "Yesterday"
        } else if calendar.isDateInToday(date) || calendar.isDateInYesterday(date) || calendar.isDate(date, equalTo: now, toGranularity: .month) {
            // Day in current month
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            // Month in current year
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        } else {
            // Year
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Top Discoveries View

struct TopDiscoveriesView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let timelineMode: ListeningTimelineView.TimelineMode
    let selectedDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Discoveries")
                .sectionHeaderStyle()
            
            if let discoveries = recentDiscoveries(limit: 3) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(discoveries.enumerated()), id: \.element.persistentID) { index, song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            HStack(spacing: 10) {
                                SongRow(song: song)
                                
                                // Growth indicator for quick rise in plays
                                if isQuickGrower(song) {
                                    VStack {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        Text("Rising")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.leading, -8)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowSeparator(.hidden)
                        
                        if index < discoveries.count - 1 {
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
            } else {
                Text("No new discoveries in this period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
    }
    
    // Get recently discovered songs that are being played frequently
    private func recentDiscoveries(limit: Int) -> [MPMediaItem]? {
        let calendar = Calendar.current
        let now = Date()
        
        // Filter songs added recently based on timeline mode
        let timeThreshold: TimeInterval
        
        switch timelineMode {
        case .week:
            timeThreshold = 60 * 60 * 24 * 7 // 1 week
        case .month:
            timeThreshold = 60 * 60 * 24 * 30 // 1 month
        case .year:
            timeThreshold = 60 * 60 * 24 * 365 // 1 year
        }
        
        // Start with all songs
        var filteredSongs = musicLibrary.songs
        
        // Additional filtering if a specific date is selected
        if let selectedDate = selectedDate {
            filteredSongs = filteredSongs.filter { song in
                guard let lastPlayed = song.lastPlayedDate else { return false }
                
                switch timelineMode {
                case .week, .month:
                    return calendar.isDate(lastPlayed, inSameDayAs: selectedDate)
                case .year:
                    return calendar.isDate(lastPlayed, equalTo: selectedDate, toGranularity: .month)
                }
            }
        }
        
        // Filter songs that are played at least 3 times
        let recentSongs = filteredSongs.filter { song in
            guard let lastPlayed = song.lastPlayedDate else { return false }
            return lastPlayed.timeIntervalSinceNow > -timeThreshold && song.playCount >= 3
        }
        
        if recentSongs.isEmpty {
            return nil
        }
        
        // Sort by play count
        let sortedDiscoveries = recentSongs.sorted { song1, song2 in
            // In a real implementation we would use dateAdded, but we'll use lastPlayedDate
            guard let lastPlayed1 = song1.lastPlayedDate, let lastPlayed2 = song2.lastPlayedDate else {
                return song1.playCount > song2.playCount
            }
            
            let daysInLibrary1 = calendar.dateComponents([.day], from: lastPlayed1, to: now).day ?? 1
            let daysInLibrary2 = calendar.dateComponents([.day], from: lastPlayed2, to: now).day ?? 1
            
            let playsPerDay1 = Double(song1.playCount) / Double(max(1, daysInLibrary1))
            let playsPerDay2 = Double(song2.playCount) / Double(max(1, daysInLibrary2))
            
            return playsPerDay1 > playsPerDay2
        }
        
        return Array(sortedDiscoveries.prefix(limit))
    }
    
    // Check if a song is growing in plays quickly
    private func isQuickGrower(_ song: MPMediaItem) -> Bool {
        guard let lastPlayed = song.lastPlayedDate else {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        let daysInLibrary = calendar.dateComponents([.day], from: lastPlayed, to: now).day ?? 1
        
        // If the song gets more than 1 play per day on average
        return Double(song.playCount) / Double(max(1, daysInLibrary)) > 1.0
    }
}

// MARK: - Listening Streak View

struct ListeningStreakView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Listening Activity")
                .sectionHeaderStyle()
            
            HStack(spacing: 20) {
                // Current streak
                VStack(alignment: .center, spacing: 8) {
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(currentStreak)")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Best streak
                VStack(alignment: .center, spacing: 8) {
                    Text("Best Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(bestStreak)")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Last active
                VStack(alignment: .center, spacing: 8) {
                    Text("Last Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(lastActiveText)
                        .font(.system(size: 18, weight: .bold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Weekly activity heatmap (simplified version)
            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly Activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<7) { dayIndex in
                        let activityLevel = activityLevelForDay(dayIndex)
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForActivityLevel(activityLevel))
                                .frame(height: 24)
                            
                            Text(dayAbbreviation(for: dayIndex))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
    }
    
    // Computed properties for streaks
    
    // Current streak (consecutive days of listening)
    private var currentStreak: Int {
        // In a real app, this would be calculated from actual listening timestamps
        // For this mockup, we'll use a simulated value
        var currentStreakDays = 0
        let calendar = Calendar.current
        let now = Date()
        
        for daysAgo in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            if hasListeningActivity(on: date) {
                currentStreakDays += 1
            } else {
                break
            }
        }
        
        return currentStreakDays
    }
    
    // Best streak (best run of consecutive days)
    private var bestStreak: Int {
        // In a real app, this would be calculated from actual listening timestamps
        // For this mockup, we'll simulate a value
        return max(currentStreak, 14) // example value
    }
    
    // Last active text
    private var lastActiveText: String {
        let calendar = Calendar.current
        let now = Date()
        
        if hasListeningActivity(on: now) {
            return "Today"
        } else if hasListeningActivity(on: calendar.date(byAdding: .day, value: -1, to: now)!) {
            return "Yesterday"
        } else {
            // Find the last active day
            for daysAgo in 2..<30 {
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
                if hasListeningActivity(on: date) {
                    if daysAgo < 7 {
                        return "\(daysAgo) days ago"
                    } else {
                        return "\(daysAgo / 7) week\(daysAgo / 7 > 1 ? "s" : "") ago"
                    }
                }
            }
            return "Long ago"
        }
    }
    
    // Helper function to check if there was listening activity on a given day
    private func hasListeningActivity(on date: Date) -> Bool {
        // In a real app, this would check actual listening data
        // For this mockup, we'll use lastPlayedDate from songs as a proxy
        let calendar = Calendar.current
        
        return musicLibrary.songs.contains { song in
            guard let lastPlayed = song.lastPlayedDate else { return false }
            return calendar.isDate(lastPlayed, equalTo: date, toGranularity: .day)
        }
    }
    
    // Get activity level for a given day of the week (0 = Sunday, 6 = Saturday)
    private func activityLevelForDay(_ dayIndex: Int) -> Double {
        // In a real app, this would aggregate actual listening data
        // For this mockup, we'll simulate activity levels
        let activityLevels: [Double] = [0.2, 0.5, 0.8, 0.6, 0.9, 1.0, 0.3]
        return activityLevels[dayIndex]
    }
    
    // Convert activity level to color
    private func colorForActivityLevel(_ level: Double) -> Color {
        if level <= 0.0 {
            return Color.gray.opacity(0.2)
        } else if level < 0.3 {
            return AppStyles.accentColor.opacity(0.3)
        } else if level < 0.6 {
            return AppStyles.accentColor.opacity(0.6)
        } else {
            return AppStyles.accentColor
        }
    }
    
    // Get abbreviated day name
    private func dayAbbreviation(for dayIndex: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[dayIndex]
    }
}
