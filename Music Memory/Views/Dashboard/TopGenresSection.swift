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
            Text("Top Genres")
                .font(AppStyles.headlineStyle)
                .padding(.horizontal)
            
            // Genre chart
            HStack(alignment: .center) {
                // Pie chart
                ZStack {
                    ForEach(Array(topGenres.prefix(5).enumerated()), id: \.element.id) { index, genre in
                        Circle()
                            .trim(from: index == 0 ? 0 : segmentStartAngle(index),
                                  to: segmentEndAngle(index + 1))
                            .stroke(colorForIndex(index), lineWidth: 25)
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
                
                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(topGenres.prefix(5).enumerated()), id: \.element.id) { index, genre in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorForIndex(index))
                                .frame(width: 10, height: 10)
                            
                            Text(genre.name)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(Int((Double(genre.totalPlayCount) / Double(totalGenrePlays) * 100).rounded()))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if topGenres.count > 5 {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 10, height: 10)
                            
                            Text("Other")
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(otherGenresPercentage)%")
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
        }
    }
    
    // MARK: - Computed Properties
    
    // Top genres sorted by play count
    private var topGenres: [GenreData] {
        musicLibrary.genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Total plays across top genres for percentage calculation
    private var totalGenrePlays: Int {
        topGenres.prefix(5).reduce(0) { $0 + $1.totalPlayCount }
    }
    
    // Percentage of plays from genres other than top 5
    private var otherGenresPercentage: Int {
        let top5Plays = topGenres.prefix(5).reduce(0) { $0 + $1.totalPlayCount }
        let otherPlays = totalGenrePlays - top5Plays
        return Int((Double(otherPlays) / Double(totalGenrePlays) * 100).rounded())
    }
    
    // Helper function to get start angle for pie chart segment
    private func segmentStartAngle(_ index: Int) -> CGFloat {
        let totalPlays = totalGenrePlays
        let previousTotal = topGenres.prefix(index).reduce(0) { $0 + $1.totalPlayCount }
        return CGFloat(previousTotal) / CGFloat(totalPlays)
    }
    
    // Helper function to get end angle for pie chart segment
    private func segmentEndAngle(_ index: Int) -> CGFloat {
        let totalPlays = totalGenrePlays
        let previousTotal = topGenres.prefix(index).reduce(0) { $0 + $1.totalPlayCount }
        return CGFloat(previousTotal) / CGFloat(totalPlays)
    }
    
    // Helper function to get color for a genre index
    private func colorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [
            AppStyles.accentColor,
            Color.blue,
            Color.green,
            Color.orange,
            Color.red
        ]
        
        return index < colors.count ? colors[index] : Color.gray
    }
}
