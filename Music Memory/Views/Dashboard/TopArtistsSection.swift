//
//  TopArtistsSection.swift
//  Music Memory
//
//  Created by Jacob Rees on 12/05/2025.
//

import SwiftUI
import MediaPlayer

struct TopArtistsSection: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !musicLibrary.filteredArtists.isEmpty {
                Text("Top Artists")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                 
                TopItemsView(
                    title: "",
                    items: Array(musicLibrary.filteredArtists.prefix(5)),
                    artwork: { $0.artwork },
                    itemTitle: { $0.name },
                    itemSubtitle: { "\($0.songs.count) songs" },
                    itemPlays: { $0.totalPlayCount },
                    iconName: { _ in "music.mic" },
                    destination: { artist, rank in ArtistDetailView(artist: artist, rank: rank) },
                    seeAllDestination: { LibraryView(selectedTab: .constant(1)) }
                )
            }
        }
    }
}
