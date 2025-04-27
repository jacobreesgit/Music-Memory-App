//
//  DashboardView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct DashboardView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        NavigationView {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading your music...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Your Music Overview")
                            .font(AppStyles.titleStyle)
                            .padding(.horizontal)
                        
                        // Top Songs
                        TopItemsView(
                            title: "Top Songs",
                            items: Array(musicLibrary.songs.prefix(5)),
                            artwork: { $0.artwork },
                            itemTitle: { $0.title ?? "Unknown" },
                            itemSubtitle: { $0.artist ?? "Unknown" },
                            itemPlays: { $0.playCount ?? 0 },
                            iconName: { _ in "music.note" },
                            destination: { SongDetailView(song: $0) }
                        )
                        
                        // Top Albums
                        TopItemsView(
                            title: "Top Albums",
                            items: Array(musicLibrary.albums.prefix(5)),
                            artwork: { $0.artwork },
                            itemTitle: { $0.title },
                            itemSubtitle: { $0.artist },
                            itemPlays: { $0.totalPlayCount },
                            iconName: { _ in "square.stack" },
                            destination: { AlbumDetailView(album: $0) }
                        )
                        
                        // Top Artists
                        TopItemsView(
                            title: "Top Artists",
                            items: Array(musicLibrary.artists.prefix(5)),
                            artwork: { $0.artwork }, // Use the artist artwork
                            itemTitle: { $0.name },
                            itemSubtitle: { "\($0.songs.count) songs" },
                            itemPlays: { $0.totalPlayCount },
                            iconName: { _ in "music.mic" },
                            destination: { ArtistDetailView(artist: $0) }
                        )
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Dashboard")
            }
        }
    }
}
