//
//  LibraryRow.swift
//  Music Memory
//
//  Created by Jacob Rees on 11/05/2025.
//

import SwiftUI
import MediaPlayer

/// Simplified LibraryRow that doesn't require generic type parameter in the factory methods
struct LibraryRow: View {
    // Display information
    let title: String
    let subtitle: String
    let playCount: Int
    
    // Visual elements
    let artwork: MPMediaItemArtwork?
    let iconName: String
    
    // Optional - for configuring shape of placeholder
    let useCircularPlaceholder: Bool
    
    // Initialize with default square placeholder
    init(
        title: String,
        subtitle: String,
        playCount: Int,
        artwork: MPMediaItemArtwork?,
        iconName: String,
        useCircularPlaceholder: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.playCount = playCount
        self.artwork = artwork
        self.iconName = iconName
        self.useCircularPlaceholder = useCircularPlaceholder
    }
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork/icon section
            if let artwork = artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: iconName)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                // Placeholder with appropriate shape
                if useCircularPlaceholder {
                    ZStack {
                        Circle()
                            .fill(AppStyles.secondaryColor)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppStyles.cornerRadius)
                            .fill(AppStyles.secondaryColor)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppStyles.bodyStyle)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppStyles.captionStyle)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            // Play count
            Text("\(playCount) plays")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
        .standardRowStyle()
    }
}

// Static factory methods - moved outside the struct to avoid generic type inference issues
extension LibraryRow {
    // Create from MPMediaItem (Song)
    static func song(_ song: MPMediaItem) -> LibraryRow {
        return LibraryRow(
            title: song.title ?? "Unknown",
            subtitle: song.artist ?? "Unknown",
            playCount: song.playCount,
            artwork: song.artwork,
            iconName: "music.note"
        )
    }
    
    // Create from AlbumData
    static func album(_ album: AlbumData) -> LibraryRow {
        return LibraryRow(
            title: album.title,
            subtitle: album.artist,
            playCount: album.totalPlayCount,
            artwork: album.artwork,
            iconName: "square.stack"
        )
    }
    
    // Create from ArtistData
    static func artist(_ artist: ArtistData) -> LibraryRow {
        return LibraryRow(
            title: artist.name,
            subtitle: "\(artist.songs.count) songs",
            playCount: artist.totalPlayCount,
            artwork: artist.artwork,
            iconName: "music.mic",
            useCircularPlaceholder: true
        )
    }
    
    // Create from GenreData
    static func genre(_ genre: GenreData) -> LibraryRow {
        return LibraryRow(
            title: genre.name,
            subtitle: "\(genre.songs.count) songs",
            playCount: genre.totalPlayCount,
            artwork: genre.artwork,
            iconName: "music.note.list"
        )
    }
    
    // Create from PlaylistData
    static func playlist(_ playlist: PlaylistData) -> LibraryRow {
        return LibraryRow(
            title: playlist.name,
            subtitle: "\(playlist.songs.count) songs",
            playCount: playlist.totalPlayCount,
            artwork: playlist.artwork,
            iconName: "music.note.list"
        )
    }
}
