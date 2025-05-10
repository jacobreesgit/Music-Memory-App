//
//  DetailHeaderView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

/// Metadata item struct for detail headers
struct MetadataItem: Identifiable {
    let id = UUID()
    let iconName: String
    let label: String
    let value: String
}

/// Reusable header view for detail screens
struct DetailHeaderView: View {
    let title: String
    let subtitle: String
    let plays: Int
    let songCount: Int
    let artwork: MPMediaItemArtwork?
    let isAlbum: Bool
    let metadata: [MetadataItem]
    let rank: Int?
    
    init(
        title: String,
        subtitle: String,
        plays: Int,
        songCount: Int,
        artwork: MPMediaItemArtwork?,
        isAlbum: Bool,
        metadata: [MetadataItem] = [],
        rank: Int? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.plays = plays
        self.songCount = songCount
        self.artwork = artwork
        self.isAlbum = isAlbum
        self.metadata = metadata
        self.rank = rank
    }
    
    var body: some View {
        VStack(spacing: AppStyles.smallPadding) {
            // Artwork or placeholder with rank badge
            ZStack(alignment: .topLeading) {
                if let artwork = artwork {
                    Image(uiImage: artwork.image(at: CGSize(width: 200, height: 200)) ?? UIImage(systemName: isAlbum ? "square.stack" : "music.mic")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .cornerRadius(AppStyles.cornerRadius)
                } else {
                    Image(systemName: isAlbum ? "square.stack" : "music.mic")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                        .padding(20)
                        .background(AppStyles.secondaryColor)
                        .cornerRadius(AppStyles.cornerRadius)
                }
                
                // Rank badge if available
                if let rank = rank {
                    Text("#\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppStyles.accentColor)
                        .cornerRadius(8)
                        .offset(x: -8, y: -8)
                }
            }
            .padding(.top, 5) // Add padding to ensure badge is fully visible
            
            // Title
            Text(title)
                .font(AppStyles.subtitleStyle)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Subtitle (artist or "")
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(AppStyles.headlineStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Play count
            Text("Total Plays: \(plays)")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
                .padding(.top, 2)
            
            // Song count
            Text("\(songCount) songs")
                .font(AppStyles.captionStyle)
                .foregroundColor(.secondary)
            
            // Metadata section
            if !metadata.isEmpty {
                HStack(alignment: .center) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(metadata) { item in
                            HStack(spacing: 6) {
                                // Icon
                                Image(systemName: item.iconName)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                
                                // Label
                                Text(item.label)
                                    .font(.footnote.bold())
                                    .foregroundColor(.secondary)
                                
                                // Value
                                Text(item.value)
                                    .font(.footnote)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
