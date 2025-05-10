//
//  GenreAnalysisSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer
import Charts

struct GenreAnalysisSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Genre Analysis")
                .sectionHeaderStyle()
            
            // Genre distribution chart
            genreDistributionChart
            
            // Genre stats
            genreStats
        }
    }
    
    private var genreDistributionChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Genres")
                .font(.subheadline)
                .foregroundColor(AppStyles.accentColor)
            
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
            }
        }
        .padding()
        .background(AppStyles.secondaryColor.opacity(0.3))
        .cornerRadius(AppStyles.cornerRadius)
        .padding(.horizontal)
    }
    
    private var genreStats: some View {
        HStack(spacing: 12) {
            // Total genres
            StatCard(
                title: "Total Genres",
                value: "\(musicLibrary.genres.count)",
                subtitle: "in library",
                icon: "music.note.list",
                color: AppStyles.accentColor
            )
            
            // Top genre dominance
            StatCard(
                title: "Top Genre",
                value: topGenres.first?.name ?? "Unknown",
                subtitle: "\(topGenreDominance)% of plays",
                icon: "star.fill",
                color: .orange
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var topGenres: [GenreData] {
        musicLibrary.genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private var topGenreDominance: Int {
        guard let topGenre = topGenres.first else { return 0 }
        let totalPlays = musicLibrary.genres.reduce(0) { $0 + $1.totalPlayCount }
        guard totalPlays > 0 else { return 0 }
        return Int((Double(topGenre.totalPlayCount) / Double(totalPlays) * 100).rounded())
    }
}
