//
//  AlbumRow.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct AlbumRow: View {
    let album: AlbumData
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork
            if let artwork = album.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "square.stack")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                Image(systemName: "square.stack")
                    .frame(width: 50, height: 50)
                    .background(AppStyles.secondaryColor)
                    .cornerRadius(AppStyles.cornerRadius)
            }
            
            // Title and Artist
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(AppStyles.bodyStyle)
                    .lineLimit(1)
                
                Text(album.artist)
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play count with "plays" text
            Text("\(album.totalPlayCount) plays")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
        .standardRowStyle()
    }
}
