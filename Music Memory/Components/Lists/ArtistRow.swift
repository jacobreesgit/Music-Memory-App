//
//  ArtistRow.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct ArtistRow: View {
    let artist: ArtistData
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork or placeholder
            if let artwork = artist.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "music.mic")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                // Fallback to icon if no artwork is available
                ZStack {
                    Circle()
                        .fill(AppStyles.secondaryColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "music.mic")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }
            }
            
            // Artist name (vertically centered)
            Text(artist.name)
                .font(AppStyles.bodyStyle)
                .lineLimit(1)
            
            Spacer()
            
            // Play count with "plays" text
            Text("\(artist.totalPlayCount) plays")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
        .standardRowStyle()
    }
}
