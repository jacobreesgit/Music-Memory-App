//
//  SongRow.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct SongRow: View {
    let song: MPMediaItem
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork
            if let artwork = song.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "music.note")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                Image(systemName: "music.note")
                    .frame(width: 50, height: 50)
                    .background(AppStyles.secondaryColor)
                    .cornerRadius(AppStyles.cornerRadius)
            }
            
            // Title and Artist
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title ?? "Unknown")
                    .font(AppStyles.bodyStyle)
                    .lineLimit(1)
                
                Text(song.artist ?? "Unknown")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play count with "plays" text
            Text("\(song.playCount ?? 0) plays")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
        .standardRowStyle()
    }
}
