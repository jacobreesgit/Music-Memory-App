//
//  PlaylistsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//

import SwiftUI
import MediaPlayer

struct PlaylistsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var searchText = ""
    @State private var sortOption = SortOption.playCount
    @State private var sortAscending = false // Default to descending
    @State private var displayedPlaylistCount = 75  // Start with 75 playlists
    @State private var isLoadingMore = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case dateAdded = "Date Added"
        case name = "Name"
        case playCount = "Play Count"
        case recentlyPlayed = "Recently Played"
        case songCount = "Song Count"
        
        var id: String { self.rawValue }
    }
    
    var filteredPlaylists: [PlaylistData] {
        if searchText.isEmpty {
            // When not searching, only show the current batch
            return Array(sortedPlaylists.prefix(displayedPlaylistCount))
        } else {
            // When searching, search through ALL playlists
            return sortedPlaylists.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var sortedPlaylists: [PlaylistData] {
        switch sortOption {
        case .playCount:
            return musicLibrary.filteredPlaylists.sorted {
                sortAscending ? $0.totalPlayCount < $1.totalPlayCount : $0.totalPlayCount > $1.totalPlayCount
            }
        case .name:
            return musicLibrary.filteredPlaylists.sorted {
                sortAscending ? $0.name < $1.name : $0.name > $1.name
            }
        case .songCount:
            return musicLibrary.filteredPlaylists.sorted {
                sortAscending ? $0.songs.count < $1.songs.count : $0.songs.count > $1.songs.count
            }
        case .dateAdded:
            return musicLibrary.filteredPlaylists.sorted {
                // Get the most recent date added for each playlist
                let date0 = $0.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                return sortAscending ? date0 < date1 : date0 > date1
            }
        case .recentlyPlayed:
            return musicLibrary.filteredPlaylists.sorted {
                // Get the most recent played date for each playlist
                let date0 = $0.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                return sortAscending ? date0 < date1 : date0 > date1
            }
        }
    }
    
    private var originalRanks: [String: Int] {
        Dictionary(uniqueKeysWithValues: sortedPlaylists.enumerated().map { ($1.id, $0 + 1) })
    }
    
    // Function to load more playlists when needed
    private func loadMorePlaylistsIfNeeded(currentItem item: PlaylistData) {
        // Check if this is approaching the end of the displayed items
        if let index = filteredPlaylists.firstIndex(where: { $0.id == item.id }),
           index >= filteredPlaylists.count - 15, // Load when 15 items from end
           displayedPlaylistCount < sortedPlaylists.count,
           !isLoadingMore,
           searchText.isEmpty {  // Only load more when not searching
            
            isLoadingMore = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Load next batch
                displayedPlaylistCount = min(displayedPlaylistCount + 75, sortedPlaylists.count)
                isLoadingMore = false
            }
        }
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading playlists...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Updated Search and Sort Bar with sort direction
                SearchSortBar(
                    searchText: $searchText,
                    sortOption: $sortOption,
                    sortAscending: $sortAscending,
                    placeholder: "Search playlists"
                )
                .padding(.top) // Added top padding to match other tabs
                .onChange(of: searchText) { oldValue, newValue in
                    // Reset batch loading when search text changes
                    if searchText.isEmpty {
                        displayedPlaylistCount = min(75, sortedPlaylists.count)
                    }
                }
                .onChange(of: sortOption) { oldValue, newValue in
                    // Reset batch loading when sort option changes
                    displayedPlaylistCount = min(75, sortedPlaylists.count)
                }
                .onChange(of: sortAscending) { oldValue, newValue in
                    // Reset batch loading when sort direction changes
                    displayedPlaylistCount = min(75, sortedPlaylists.count)
                }

                if musicLibrary.filteredPlaylists.isEmpty {
                    // Show message when there are no playlists in the library
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                        
                        Text("No playlists found in your library")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Playlists with play count information will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(filteredPlaylists.enumerated()), id: \.element.id) { index, playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist, rank: originalRanks[playlist.id])) {
                                HStack(spacing: 10) {
                                    Text("#\(originalRanks[playlist.id] ?? 0)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppStyles.accentColor)
                                        .frame(width: 30, alignment: .leading)
                                    
                                    LibraryRow.playlist(playlist)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .onAppear {
                                // Trigger loading more playlists when reaching the end
                                loadMorePlaylistsIfNeeded(currentItem: playlist)
                            }
                        }
                        
                        // Loading indicator when fetching more playlists
                        if isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                        }
                        
                        // "Load More" button when there are more playlists and not searching
                        if displayedPlaylistCount < sortedPlaylists.count && !isLoadingMore && searchText.isEmpty {
                            Button(action: {
                                isLoadingMore = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    displayedPlaylistCount = min(displayedPlaylistCount + 75, sortedPlaylists.count)
                                    isLoadingMore = false
                                }
                            }) {
                                Text("Load More Playlists")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppStyles.secondaryColor)
                                    .cornerRadius(AppStyles.cornerRadius)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .listRowSeparator(.hidden)
                        }
                        
                        if filteredPlaylists.isEmpty && !searchText.isEmpty {
                            Text("No playlists found matching '\(searchText)'")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollDismissesKeyboard(.immediately) // Dismiss keyboard when scrolling begins
                }
            }
        }
    }
}
