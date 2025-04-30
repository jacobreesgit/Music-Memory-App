//
//  TopItemsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct TopItem {
    let title: String
    let subtitle: String
    let plays: Int
    let artwork: MPMediaItemArtwork?
}

/// A reusable horizontal carousel for displaying top items
struct TopItemsView<T, DestinationView: View>: View {
    let title: String
    let items: [T]
    let artwork: (T) -> MPMediaItemArtwork?
    let itemTitle: (T) -> String
    let itemSubtitle: (T) -> String
    let itemPlays: (T) -> Int
    let iconName: (T) -> String
    let destination: (T) -> DestinationView
    
    var body: some View {
        VStack(alignment: .leading) {
            if !title.isEmpty {
                Text(title)
                    .font(AppStyles.headlineStyle)
                    .padding(.horizontal)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        NavigationLink(destination: destination(item)) {
                            VStack {
                                // Rank badge
                                ZStack(alignment: .topLeading) {
                                    // Artwork or placeholder
                                    if let artwork = artwork(item) {
                                        Image(uiImage: artwork.image(at: CGSize(width: 100, height: 100)) ?? UIImage(systemName: "music.note")!)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(AppStyles.cornerRadius)
                                    } else {
                                        Image(systemName: iconName(item))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 80, height: 80)
                                            .padding(10)
                                            .background(AppStyles.secondaryColor)
                                            .cornerRadius(AppStyles.cornerRadius)
                                    }
                                    
                                    // Rank badge
                                    Text("#\(index + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(AppStyles.accentColor)
                                        .cornerRadius(8)
                                        .offset(x: -5, y: -5)
                                }
                                
                                // Title
                                Text(itemTitle(item))
                                    .font(AppStyles.bodyStyle)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                
                                // Subtitle
                                Text(itemSubtitle(item))
                                    .font(AppStyles.captionStyle)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                // Play count
                                Text("\(itemPlays(item)) plays")
                                    .font(AppStyles.captionStyle)
                                    .foregroundColor(AppStyles.accentColor)
                            }
                            .frame(width: 100)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
