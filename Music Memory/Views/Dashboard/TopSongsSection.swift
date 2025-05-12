//
//  TopSongsSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 12/05/2025.
//

import SwiftUI
import MediaPlayer

struct TopSongsSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !musicLibrary.filteredSongs.isEmpty {
                Text("Top Songs")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                 
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredSongs.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.title ?? "Unknown" },
                    itemSubtitle: { $0.artist ?? "Unknown" },
                    itemPlays: { $0.playCount },
                    iconName: { _ in "music.note" },
                    destination: { song, rank in SongDetailView(song: song, rank: rank) },
                    seeAllDestination: { LibraryView(selectedTab: .constant(0)) }
                )
            }
        }
    }
}
