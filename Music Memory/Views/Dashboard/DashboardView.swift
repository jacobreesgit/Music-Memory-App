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
    @State private var refreshID = UUID()
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading your music...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    // Invisible anchor for scrolling to top with zero height
                    Text("")
                        .id("top")
                        .frame(height: 0)
                        .padding(0)
                        .opacity(0)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Top Songs
                            Text("Top Songs")
                                .sectionHeaderStyle()
                            
                            TopItemsView(
                                title: "",
                                items: Array(musicLibrary.songs.prefix(5)),
                                artwork: { $0.artwork },
                                itemTitle: { $0.title ?? "Unknown" },
                                itemSubtitle: { $0.artist ?? "Unknown" },
                                itemPlays: { $0.playCount ?? 0 },
                                iconName: { _ in "music.note" },
                                destination: { SongDetailView(song: $0) }
                            )
                            
                            // Top Albums
                            Text("Top Albums")
                                .sectionHeaderStyle()
                            
                            TopItemsView(
                                title: "",
                                items: Array(musicLibrary.albums.prefix(5)),
                                artwork: { $0.artwork },
                                itemTitle: { $0.title },
                                itemSubtitle: { $0.artist },
                                itemPlays: { $0.totalPlayCount },
                                iconName: { _ in "square.stack" },
                                destination: { AlbumDetailView(album: $0) }
                            )
                            
                            // Top Artists
                            Text("Top Artists")
                                .sectionHeaderStyle()
                            
                            TopItemsView(
                                title: "",
                                items: Array(musicLibrary.artists.prefix(5)),
                                artwork: { $0.artwork },
                                itemTitle: { $0.name },
                                itemSubtitle: { "\($0.songs.count) songs" },
                                itemPlays: { $0.totalPlayCount },
                                iconName: { _ in "music.mic" },
                                destination: { ArtistDetailView(artist: $0) }
                            )
                            
                            // Top Playlist
                            if !musicLibrary.playlists.isEmpty {
                                Text("Top Playlists")
                                    .sectionHeaderStyle()
                                
                                TopItemsView(
                                    title: "",
                                    items: Array(musicLibrary.playlists.prefix(5)),
                                    artwork: { $0.artwork },
                                    itemTitle: { $0.name },
                                    itemSubtitle: { "\($0.songs.count) songs" },
                                    itemPlays: { $0.totalPlayCount },
                                    iconName: { _ in "music.note.list" },
                                    destination: { PlaylistDetailView(playlist: $0) }
                                )
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .id(refreshID)
                }
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
    }
}
