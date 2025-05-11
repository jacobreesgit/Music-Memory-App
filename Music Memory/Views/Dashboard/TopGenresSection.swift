//
//  TopGenresSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer
import Charts

struct TopGenresSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Genre Distribution")
                .font(AppStyles.headlineStyle)
                .padding(.horizontal)
            
            // Genre chart
            HStack(alignment: .center) {
                // Pie chart
                ZStack {
                    // Draw the pie chart segments based on normalized percentages
                    ForEach(Array(normalizedGenreData.enumerated()), id: \.element.id) { index, item in
                        Circle()
                            .trim(from: item.startAngle, to: item.endAngle)
                            .stroke(item.color, lineWidth: 25)
                            .frame(width: 100)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    VStack {
                        Text("\(topGenres.count)")
                            .font(.system(size: 20, weight: .bold))
                        Text("genres")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 150, height: 150)
                .padding(.leading)
                
                // Legend with percentages that add up to exactly 100%
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(normalizedGenreData.prefix(normalizedGenreData.count - (hasOtherCategory ? 1 : 0))), id: \.id) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            
                            Text(item.name)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(item.percentage)%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Show "Other" category if it exists
                    if hasOtherCategory, let otherCategory = normalizedGenreData.last {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(otherCategory.color)
                                .frame(width: 10, height: 10)
                            
                            Text("Other")
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(otherCategory.percentage)%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.trailing)
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(AppStyles.secondaryColor.opacity(0.3))
            .cornerRadius(AppStyles.cornerRadius)
            .padding(.horizontal)
            
            // Top genres bar chart
            if !topGenres.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Genres")
                        .font(.subheadline)
                        .foregroundColor(AppStyles.accentColor)
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(topGenres.prefix(5), id: \.name) { genre in
                            BarMark(
                                x: .value("Plays", genre.totalPlayCount),
                                y: .value("Genre", genre.name)
                            )
                            .foregroundStyle(AppStyles.accentColor.gradient)
                        }
                    }
                    .frame(height: 150)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    // Struct to hold normalized genre data
    private struct NormalizedGenreItem: Identifiable {
        let id = UUID()
        let name: String
        let percentage: Int
        let startAngle: CGFloat
        let endAngle: CGFloat
        let color: Color
    }
    
    // Top genres sorted by play count
    private var topGenres: [GenreData] {
        musicLibrary.genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Total plays across all genres for percentage calculation
    private var totalGenrePlays: Int {
        musicLibrary.genres.reduce(0) { $0 + $1.totalPlayCount }
    }
    
    // Check if we need to display an "Other" category
    private var hasOtherCategory: Bool {
        let top5Plays = topGenres.prefix(5).reduce(0) { $0 + $1.totalPlayCount }
        return top5Plays < totalGenrePlays
    }
    
    // Define a consistent gray color for the "Other" category
    private let otherCategoryColor = Color.gray
    
    // Colors for each category
    private var categoryColors: [Color] {
        [
            AppStyles.accentColor,
            Color.blue,
            Color.green,
            Color.orange,
            Color.red,
            otherCategoryColor // "Other" is always this specific gray
        ]
    }
    
    // Normalized genre data with percentages that sum to exactly 100%
    private var normalizedGenreData: [NormalizedGenreItem] {
        // Get raw percentages for top 5 genres
        let top5Genres = Array(topGenres.prefix(5))
        var rawPercentages = top5Genres.map { Double($0.totalPlayCount) / Double(max(1, totalGenrePlays)) * 100 }
        
        // Calculate other percentage
        let top5Sum = rawPercentages.reduce(0, +)
        let otherRaw = max(0, 100 - top5Sum)
        
        // Combine all percentages if there's an "Other" category
        if otherRaw > 0 {
            rawPercentages.append(otherRaw)
        }
        
        // Round percentages to integers while ensuring they sum to 100%
        let roundedPercentages = roundPercentagesToWholeNumbers(rawPercentages)
        
        // Create normalized data with angles
        var result: [NormalizedGenreItem] = []
        var currentAngle: CGFloat = 0
        
        // Process top 5 genres
        for (index, genre) in top5Genres.enumerated() {
            guard index < roundedPercentages.count else { break }
            let percentage = roundedPercentages[index]
            
            // Only include genres with non-zero percentage
            if percentage > 0 {
                let startAngle = currentAngle
                let endAngle = currentAngle + CGFloat(percentage) / 100.0
                
                result.append(NormalizedGenreItem(
                    name: genre.name,
                    percentage: percentage,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    color: categoryColors[index]
                ))
                
                currentAngle = endAngle
            }
        }
        
        // Add "Other" category if needed
        if otherRaw > 0 && roundedPercentages.count > top5Genres.count {
            let otherPercentage = roundedPercentages[top5Genres.count]
            
            // Only include if percentage is non-zero
            if otherPercentage > 0 {
                let startAngle = currentAngle
                let endAngle = currentAngle + CGFloat(otherPercentage) / 100.0
                
                result.append(NormalizedGenreItem(
                    name: "Other",
                    percentage: otherPercentage,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    color: otherCategoryColor
                ))
            }
        }
        
        return result
    }
    
    // Helper function to ensure percentages round to whole numbers and sum to exactly 100%
    private func roundPercentagesToWholeNumbers(_ percentages: [Double]) -> [Int] {
        // First, round down all percentages
        var roundedDown = percentages.map { Int($0) }
        
        // Calculate how much we need to distribute to make sum 100
        let roundedSum = roundedDown.reduce(0, +)
        var remainder = 100 - roundedSum
        
        // Get fractional parts to determine which values to round up
        let fractionalParts = percentages.map { $0 - Double(Int($0)) }
        
        // Create index-value pairs and sort by fractional part (descending)
        let indexedFractions = fractionalParts.enumerated()
            .map { (index: $0, fraction: $1) }
            .sorted { $0.fraction > $1.fraction }
        
        // Distribute the remainder to indexes with largest fractional parts
        for i in 0..<min(remainder, indexedFractions.count) {
            let index = indexedFractions[i].index
            roundedDown[index] += 1
        }
        
        return roundedDown
    }
}
