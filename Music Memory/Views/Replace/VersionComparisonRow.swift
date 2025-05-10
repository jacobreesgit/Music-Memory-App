//
//  VersionComparisonRow.swift
//  Music Memory
//
//  Created by Jacob Rees on 10/05/2025.
//

import SwiftUI
import MediaPlayer
import MusicKit

struct VersionComparisonRow: View {
    let librarySong: MPMediaItem
    let catalogSong: Song
    let isSelected: Bool
    let differences: [VersionDifference]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Song title & selection indicator
            HStack {
                Text(catalogSong.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppStyles.accentColor)
                        .font(.system(size: 18))
                }
            }
            
            // Song detail row
            HStack(spacing: 12) {
                // Artwork
                Group {
                    if let artwork = catalogSong.artwork {
                        ArtworkImage(artwork: artwork, width: 60)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 30))
                            .frame(width: 60, height: 60)
                            .background(AppStyles.secondaryColor)
                            .cornerRadius(AppStyles.cornerRadius)
                    }
                }
                .cornerRadius(AppStyles.cornerRadius)
                
                // Song information
                VStack(alignment: .leading, spacing: 2) {
                    // Artist
                    Text(catalogSong.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Album
                    if let albumTitle = catalogSong.albumTitle {
                        Text(albumTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Duration
                    if let duration = catalogSong.duration {
                        Text("\(formatDuration(duration)) • \(formattedReleaseYear(catalogSong.releaseDate))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Version tags
                if catalogSong.audioVariants.contains(.dolbyAtmos) {
                    Image(systemName: "airpods.gen3")
                        .foregroundColor(.purple)
                        .font(.system(size: 16))
                }
                
                if catalogSong.contentRating == .explicit {
                    Text("E")
                        .font(.system(size: 12, weight: .bold))
                        .padding(4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                }
            }
            
            // Version differences
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(differences) { difference in
                        VersionDifferenceTag(difference: difference)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isSelected ? AppStyles.secondaryColor.opacity(0.5) : Color.clear)
        .cornerRadius(AppStyles.cornerRadius)
    }
    
    private func formatDuration(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formattedReleaseYear(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}

struct ArtworkImage: View {
    let artwork: Artwork
    let width: CGFloat
    @State private var image: Image?
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
            }
        }
        .frame(width: width, height: width)
        .background(AppStyles.secondaryColor)
        .cornerRadius(AppStyles.cornerRadius)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        Task {
            if let url = artwork.url(width: 100, height: 100),
               let (data, _) = try? await URLSession.shared.data(from: url),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.image = Image(uiImage: uiImage)
                }
            }
        }
    }
}
