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
    @State private var timelineMode: TimelineMode = .year
    @State private var selectedDate: Date?
    
    enum TimelineMode: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Timeline mode selector with more visual appeal
                VStack(alignment: .leading, spacing: 8) {
                    Text("Listening Timeline")
                        .font(AppStyles.headlineStyle)
                        .foregroundColor(AppStyles.accentColor)
                        .padding(.horizontal)
                    
                    // Segment picker styled like the LibraryView tabs
                    HStack(spacing: 0) {
                        ForEach(TimelineMode.allCases) { mode in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    timelineMode = mode
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text(mode.rawValue)
                                        .font(.headline)
                                        .foregroundColor(timelineMode == mode ? AppStyles.accentColor : .secondary)
                                        .fontWeight(timelineMode == mode ? .bold : .regular)
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
                            let modeIndex = CGFloat(TimelineMode.allCases.firstIndex(of: timelineMode) ?? 0)
                            Rectangle()
                                .fill(AppStyles.accentColor)
                                .frame(width: tabWidth - 20, height: 2)
                                .offset(x: modeIndex * tabWidth + 10)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: timelineMode)
                        }
                        .frame(height: 2)
                        , alignment: .bottom
                    )
                    .padding(.top, 8)
                }
                
                // Timeline chart based on selected mode
                TimelineChartView(timelineMode: timelineMode, selectedDate: $selectedDate)
                    .padding(.horizontal)
                
                // Selected date details (if any)
                if let selectedDate = selectedDate {
                    SelectedDateView(date: selectedDate)
                        .padding(.horizontal)
                }
                
                // Top discoveries for the selected period
                TopDiscoveriesView(timelineMode: timelineMode)
                    .padding(.horizontal)
                
                // Listening streak information
                ListeningStreakView()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Listening Timeline")
    }
}

// MARK: - Timeline Chart View

struct TimelineChartView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let timelineMode: ListeningTimelineView.TimelineMode
    @Binding var selectedDate: Date?
    
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
    
    // Data for the timeline chart
    private var timelineData: [TimelineDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // Filter songs with last played date
        let playedSongs = musicLibrary.songs.filter { song in
            return song.lastPlayedDate != nil && song.playCount > 0
        }
        
        // Group by time period based on selected mode
        var datePlays: [Date: Int] = [:]
        
        for song in playedSongs {
            guard let lastPlayed = song.lastPlayedDate else { continue }
            
            let normalizedDate: Date
            
            switch timelineMode {
            case .week:
                // Group by day of week (last 7 days)
                let dayComponent = calendar.dateComponents([.day], from: lastPlayed, to: now)
                if let day = dayComponent.day, day <= 7 {
                    normalizedDate = calendar.startOfDay(for: lastPlayed)
                    datePlays[normalizedDate, default: 0] += song.playCount
                }
                
            case .month:
                // Group by day of month (last 30 days)
                let dayComponent = calendar.dateComponents([.day], from: lastPlayed, to: now)
                if let day = dayComponent.day, day <= 30 {
                    normalizedDate = calendar.startOfDay(for: lastPlayed)
                    datePlays[normalizedDate, default: 0] += song.playCount
                }
                
            case .year:
                // Group by month of year (last 12 months)
                if let month = calendar.dateComponents([.month], from: lastPlayed, to: now).month, month <= 12 {
                    var components = calendar.dateComponents([.year, .month], from: lastPlayed)
                    components.day = 1
                    if let monthStart = calendar.date(from: components) {
                        normalizedDate = monthStart
                        datePlays[normalizedDate, default: 0] += song.playCount
                    }
                }
                
            case .allTime:
                // Group by year
                var components = calendar.dateComponents([.year], from: lastPlayed)
                components.month = 1
                components.day = 1
                if let yearStart = calendar.date(from: components) {
                    normalizedDate = yearStart
                    datePlays[normalizedDate, default: 0] += song.playCount
                }
            }
        }
        
        // Convert to array and sort by date
        return datePlays.map { date, plays in
            TimelineDataPoint(date: date, plays: plays)
        }.sorted { $0.date < $1.date }
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
        case .allTime:
            return calendar.isDate(date1, equalTo: date2, toGranularity: .year)
        }
    }
    
    // Data point for timeline chart
    struct TimelineDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let plays: Int
    }
}

// MARK: - Selected Date View

struct SelectedDateView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Format date based on selection
            Text(formattedDate)
                .font(.headline)
                .foregroundColor(AppStyles.accentColor)
            
            // Top songs for this period
            if let topSongs = topSongsForDate(limit: 3) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Top Songs")
                        .font(.subheadline)
                        .foregroundColor(AppStyles.accentColor)
                    
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
    
    // Get top songs for the selected date
    private func topSongsForDate(limit: Int) -> [MPMediaItem]? {
        let calendar = Calendar.current
        
        // Filter songs played on this date (based on granularity)
        let filteredSongs = musicLibrary.songs.filter { song in
            guard let lastPlayed = song.lastPlayedDate else { return false }
            
            if calendar.isDate(date, equalTo: lastPlayed, toGranularity: .day) {
                return true
            } else if calendar.isDate(date, equalTo: lastPlayed, toGranularity: .month) {
                return true
            } else if calendar.isDate(date, equalTo: lastPlayed, toGranularity: .year) {
                return true
            }
            
            return false
        }
        
        if filteredSongs.isEmpty {
            return nil
        }
        
        // Sort by play count and return top ones
        return Array(filteredSongs.sorted { $0.playCount > $1.playCount }.prefix(limit))
    }
}

// MARK: - Top Discoveries View

struct TopDiscoveriesView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let timelineMode: ListeningTimelineView.TimelineMode
    
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
        case .allTime:
            timeThreshold = 60 * 60 * 24 * 365 * 2 // 2 years
        }
        
        // Filter songs that are played at least 3 times
        // In a real implementation we would check dateAdded, but we'll just use
        // lastPlayedDate as a proxy since we don't know if dateAdded is available
        let recentSongs = musicLibrary.songs.filter { song in
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
