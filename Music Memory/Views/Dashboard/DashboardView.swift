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
    
    var hasNoData: Bool {
        return musicLibrary.filteredSongs.isEmpty &&
               musicLibrary.filteredAlbums.isEmpty &&
               musicLibrary.filteredArtists.isEmpty &&
               musicLibrary.filteredPlaylists.isEmpty
    }
    
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
                    
                    if hasNoData {
                        // Show message when there is no data in the library
                        VStack(spacing: 20) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                                .padding(.top, 50)
                            
                            Text("No music data found in your library")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Music with play count information will appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Summary Section
                                DashboardSummaryView()
                                
                                // All analytics sections
                                LibraryOverviewSection()
                                GenreAnalysisSection()
                                TimeAndDurationSection()
                                ListeningPatternsSection()
                                
                                // Top content sections
                                topSongsSection
                                topAlbumsSection
                                topArtistsSection
                                topPlaylistsSection
                            }
                            .padding(.bottom, 20)
                        }
                        .scrollDismissesKeyboard(.immediately)
                        .id(refreshID)
                    }
                }
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
    }
    
    // MARK: - Top Content Sections
    
    @ViewBuilder
    private var topSongsSection: some View {
        if !musicLibrary.filteredSongs.isEmpty {
            Text("Top Songs")
                .sectionHeaderStyle()
            
            TopItemsView(
                title: "",
                items: Array(musicLibrary.filteredSongs.prefix(5)),
                artwork: { $0.artwork },
                itemTitle: { $0.title ?? "Unknown" },
                itemSubtitle: { $0.artist ?? "Unknown" },
                itemPlays: { $0.playCount },
                iconName: { _ in "music.note" },
                destination: { song, rank in SongDetailView(song: song, rank: rank) }
            )
        }
    }
    
    @ViewBuilder
    private var topAlbumsSection: some View {
        if !musicLibrary.filteredAlbums.isEmpty {
            Text("Top Albums")
                .sectionHeaderStyle()
            
            TopItemsView(
                title: "",
                items: Array(musicLibrary.filteredAlbums.prefix(5)),
                artwork: { $0.artwork },
                itemTitle: { $0.title },
                itemSubtitle: { $0.artist },
                itemPlays: { $0.totalPlayCount },
                iconName: { _ in "square.stack" },
                destination: { album, rank in AlbumDetailView(album: album, rank: rank) }
            )
        }
    }
    
    @ViewBuilder
    private var topArtistsSection: some View {
        if !musicLibrary.filteredArtists.isEmpty {
            Text("Top Artists")
                .sectionHeaderStyle()
            
            TopItemsView(
                title: "",
                items: Array(musicLibrary.filteredArtists.prefix(5)),
                artwork: { $0.artwork },
                itemTitle: { $0.name },
                itemSubtitle: { "\($0.songs.count) songs" },
                itemPlays: { $0.totalPlayCount },
                iconName: { _ in "music.mic" },
                destination: { artist, rank in ArtistDetailView(artist: artist, rank: rank) }
            )
        }
    }
    
    @ViewBuilder
    private var topPlaylistsSection: some View {
        if !musicLibrary.filteredPlaylists.isEmpty {
            Text("Top Playlists")
                .sectionHeaderStyle()
            
            TopItemsView(
                title: "",
                items: Array(musicLibrary.filteredPlaylists.prefix(5)),
                artwork: { $0.artwork },
                itemTitle: { $0.name },
                itemSubtitle: { "\($0.songs.count) songs" },
                itemPlays: { $0.totalPlayCount },
                iconName: { _ in "music.note.list" },
                destination: { playlist, rank in PlaylistDetailView(playlist: playlist, rank: rank) }
            )
        }
    }
}
