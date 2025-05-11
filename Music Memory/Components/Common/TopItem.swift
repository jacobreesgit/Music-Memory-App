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
struct TopItemsView<T, DestinationView: View, AllItemsView: View>: View {
    let title: String
    let items: [T]
    let artwork: (T) -> MPMediaItemArtwork?
    let itemTitle: (T) -> String
    let itemSubtitle: (T) -> String
    let itemPlays: (T) -> Int
    let iconName: (T) -> String
    let destination: (T, Int) -> DestinationView
    let seeAllDestination: () -> AllItemsView
    
    var body: some View {
        VStack(alignment: .leading) {
            if !title.isEmpty {
                Text(title)
                    .font(AppStyles.headlineStyle)
                    .padding(.horizontal)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // Regular items (limit to 5)
                    ForEach(Array(items.prefix(5).enumerated()), id: \.offset) { index, item in
                        NavigationLink(destination: destination(item, index + 1)) {
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
                                // Add spacing to ensure badge is fully visible
                                .padding(.top, 5)
                                
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
                    
                    // "See All" item
                    NavigationLink(destination: seeAllDestination()) {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(AppStyles.secondaryColor)
                                    .frame(width: 100, height: 100)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "arrow.right.circle")
                                        .font(.system(size: 30))
                                        .foregroundColor(AppStyles.accentColor)
                                    
                                    Text("See All")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppStyles.accentColor)
                                }
                            }
                            .frame(width: 100, height: 100)
                            
                            // Empty space to match layout of other items
                            Spacer().frame(height: 18)
                            Spacer().frame(height: 16)
                            Spacer().frame(height: 14)
                        }
                        .frame(width: 100)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
