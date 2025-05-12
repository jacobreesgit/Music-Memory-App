//  VersionComparisonRow.swift
//  Music Memory

import SwiftUI
import MediaPlayer
import MusicKit

struct VersionComparisonRow: View {
    let librarySong: MPMediaItem
    let catalogSong: Song?
    let isSelected: Bool
    let differences: [VersionDifference]
    let isOriginal: Bool
    
    // New initializer specifically for original library songs
    init(librarySong: MPMediaItem, isOriginal: Bool = false) {
        self.librarySong = librarySong
        self.catalogSong = nil
        self.isSelected = false
        self.differences = []
        self.isOriginal = true
    }
    
    // Standard initializer for catalog songs
    init(librarySong: MPMediaItem, catalogSong: Song, isSelected: Bool, differences: [VersionDifference], isOriginal: Bool = false) {
        self.librarySong = librarySong
        self.catalogSong = catalogSong
        self.isSelected = isSelected
        self.differences = differences
        self.isOriginal = isOriginal
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Song title & selection indicator
            HStack {
                Text(isOriginal ? (librarySong.title ?? "Unknown") : (catalogSong?.title ?? "Unknown"))
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppStyles.accentColor)
                        .font(.system(size: 18))
                } else if isOriginal {
                    // Show original version indicator
                    Text("Current")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                }
            }
            
            // Song detail row
            HStack(spacing: 12) {
                // Artwork handling
                if isOriginal, let libraryArtwork = librarySong.artwork {
                    Image(uiImage: libraryArtwork.image(at: CGSize(width: 60, height: 60)) ?? UIImage(systemName: "music.note")!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(AppStyles.cornerRadius)
                } else if !isOriginal, let artwork = catalogSong?.artwork {
                    // Direct handling of catalog song artwork
                    catalogArtworkView(artwork, width: 60)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 30))
                        .frame(width: 60, height: 60)
                        .background(AppStyles.secondaryColor)
                        .cornerRadius(AppStyles.cornerRadius)
                }
                
                // Song information
                VStack(alignment: .leading, spacing: 2) {
                    // Artist
                    Text(isOriginal ? (librarySong.artist ?? "Unknown Artist") : (catalogSong?.artistName ?? "Unknown Artist"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Album
                    if isOriginal {
                        if let albumTitle = librarySong.albumTitle {
                            Text(albumTitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else if let albumTitle = catalogSong?.albumTitle {
                        Text(albumTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Duration
                    if isOriginal {
                        let duration = librarySong.playbackDuration
                        Text("\(formatDuration(duration)) • \(formattedReleaseYear(librarySong.releaseDate))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else if let duration = catalogSong?.duration {
                        Text("\(formatDuration(duration)) • \(formattedReleaseYear(catalogSong?.releaseDate))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Version tags
                if isOriginal {
                    // Play count for original
                    HStack(spacing: 4) {
                        Text("\(librarySong.playCount)")
                            .font(.system(size: 14, weight: .medium))
                        Text("plays")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppStyles.accentColor)
                } else {
                    // Special audio features for catalog version
                    if catalogSong?.audioVariants?.contains(.dolbyAtmos) == true {
                        Image(systemName: "airpods.gen3")
                            .foregroundColor(.purple)
                            .font(.system(size: 16))
                    }
                    
                    if catalogSong?.contentRating == .explicit {
                        Text("E")
                            .font(.system(size: 12, weight: .bold))
                            .padding(4)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Version differences - only for alternatives with differences
            if !isOriginal && !differences.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(differences) { difference in
                            VersionDifferenceTag(difference: difference)
                        }
                    }
                }
            }
            // Removed the "Original version • X plays" text for original versions
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isSelected ? AppStyles.secondaryColor.opacity(0.5) : Color.clear) // Removed blue background for original
        .cornerRadius(AppStyles.cornerRadius)
    }
    
    // Helper methods remain the same
    @ViewBuilder
    private func catalogArtworkView(_ artwork: Artwork, width: CGFloat) -> some View {
        // Implementation remains the same
        ZStack {
            Rectangle()
                .fill(AppStyles.secondaryColor)
                .frame(width: width, height: width)
                .cornerRadius(AppStyles.cornerRadius)
            
            if let url = artwork.url(width: Int(width * 2), height: Int(width * 2)) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "music.note")
                            .font(.system(size: width * 0.5))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: width, height: width)
                .cornerRadius(AppStyles.cornerRadius)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: width * 0.5))
            }
        }
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
