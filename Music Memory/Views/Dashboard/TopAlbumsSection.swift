//
//  TopAlbumsSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 12/05/2025.
//

import SwiftUI
import MediaPlayer

struct TopAlbumsSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !musicLibrary.filteredAlbums.isEmpty {
                Text("Top Albums")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                 
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredAlbums.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.title },
                    itemSubtitle: { $0.artist },
                    itemPlays: { $0.totalPlayCount },
                    iconName: { _ in "square.stack" },
                    destination: { album, rank in AlbumDetailView(album: album, rank: rank) },
                    seeAllDestination: { LibraryView(selectedTab: .constant(2)) }
                )
            }
        }
    }
}
