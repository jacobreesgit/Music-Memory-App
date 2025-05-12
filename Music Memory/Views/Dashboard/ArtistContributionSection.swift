//
//  ArtistContributionSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 12/05/2025.
//

import SwiftUI
import MediaPlayer

struct ArtistContributionSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    // Artist contribution properties
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
}
