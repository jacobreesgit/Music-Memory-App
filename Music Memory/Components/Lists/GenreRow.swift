//
//  GenreRow.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//

import SwiftUI
import MediaPlayer

struct GenreRow: View {
    let genre: GenreData
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork or placeholder
            if let artwork = genre.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "music.note.list")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: AppStyles.cornerRadius)
                        .fill(AppStyles.secondaryColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(genre.name)
                    .font(AppStyles.bodyStyle)
                    .lineLimit(1)
                
                Text("\(genre.songs.count) songs")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text("\(genre.totalPlayCount) plays")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
        .standardRowStyle()
    }
}
