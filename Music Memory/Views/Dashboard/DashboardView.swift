//
//  DashboardView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//  Enhanced with modular components for better maintainability
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
                ScrollView {
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
                        VStack(alignment: .leading, spacing: 32) {
                            // Stats Carousel Section (includes impressive stats)
                            StatsCarouselSection()
                            
                            // Recently Played Section
                            RecentlyPlayedSection()
                            
                            // Top Artists Section
                            TopArtistsSection()
                            
                            // Recently Added Section
                            RecentlyAddedSection()
                            
                            // Top Songs
                            TopSongsSection()
                            
                            // Top Albums
                            TopAlbumsSection()
                            
                            // Genre visualization (using separate component)
                            TopGenresSection()
                            
                            // Artist contribution visualization
                            ArtistContributionSection()
                            
                            // Top Playlists
                            TopPlaylistsSection()
                        }
                        .padding(.bottom, 20)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .id(refreshID)
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                }
                .navigationTitle("Dashboard")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
