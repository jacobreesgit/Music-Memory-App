//
//  ArtistsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct ArtistsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var searchText = ""
    @State private var sortOption = SortOption.playCount
    @State private var sortAscending = false // Default to descending
    @State private var displayedArtistCount = 75  // Start with 75 artists
    @State private var isLoadingMore = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case dateAdded = "Date Added"
        case name = "Name"
        case playCount = "Play Count"
        case recentlyPlayed = "Recently Played"
        case songCount = "Song Count"
        
        var id: String { self.rawValue }
    }

    
    var filteredArtists: [ArtistData] {
        if searchText.isEmpty {
            // When not searching, only show the current batch
            return Array(sortedArtists.prefix(displayedArtistCount))
        } else {
            // When searching, search through ALL artists
            return sortedArtists.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var sortedArtists: [ArtistData] {
        switch sortOption {
        case .playCount:
            return musicLibrary.filteredArtists.sorted {
                sortAscending ? $0.totalPlayCount < $1.totalPlayCount : $0.totalPlayCount > $1.totalPlayCount
            }
        case .name:
            return musicLibrary.filteredArtists.sorted {
                sortAscending ? $0.name < $1.name : $0.name > $1.name
            }
        case .songCount:
            return musicLibrary.filteredArtists.sorted {
                sortAscending ? $0.songs.count < $1.songs.count : $0.songs.count > $1.songs.count
            }
        case .dateAdded:
            return musicLibrary.filteredArtists.sorted {
                // Get the most recent date added for each artist
                let date0 = $0.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                return sortAscending ? date0 < date1 : date0 > date1
            }
        case .recentlyPlayed:
            return musicLibrary.filteredArtists.sorted {
                // Get the most recent played date for each artist
                let date0 = $0.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                return sortAscending ? date0 < date1 : date0 > date1
            }
        }
    }
    
    private var originalRanks: [String: Int] {
        Dictionary(uniqueKeysWithValues: sortedArtists.enumerated().map { ($1.id, $0 + 1) })
    }
    
    // Function to load more artists when needed
    private func loadMoreArtistsIfNeeded(currentItem item: ArtistData) {
        // Check if this is approaching the end of the displayed items
        if let index = filteredArtists.firstIndex(where: { $0.id == item.id }),
           index >= filteredArtists.count - 15, // Load when 15 items from end
           displayedArtistCount < sortedArtists.count,
           !isLoadingMore,
           searchText.isEmpty {  // Only load more when not searching
            
            isLoadingMore = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Load next batch
                displayedArtistCount = min(displayedArtistCount + 75, sortedArtists.count)
                isLoadingMore = false
            }
        }
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading artists...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Updated Search and Sort Bar with sort direction
                SearchSortBar(
                    searchText: $searchText,
                    sortOption: $sortOption,
                    sortAscending: $sortAscending,
                    placeholder: "Search artists"
                )
                .padding(.top) // Added top padding to match other tabs
                .onChange(of: searchText) { oldValue, newValue in
                    // Reset batch loading when search text changes
                    if searchText.isEmpty {
                        displayedArtistCount = min(75, sortedArtists.count)
                    }
                }
                .onChange(of: sortOption) { oldValue, newValue in
                    // Reset batch loading when sort option changes
                    displayedArtistCount = min(75, sortedArtists.count)
                }
                .onChange(of: sortAscending) { oldValue, newValue in
                    // Reset batch loading when sort direction changes
                    displayedArtistCount = min(75, sortedArtists.count)
                }

                if musicLibrary.filteredArtists.isEmpty {
                    // Show message when there are no artists in the library
                    VStack(spacing: 20) {
                        Image(systemName: "music.mic")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                        
                        Text("No artists found in your library")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Artists with play count information will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(filteredArtists.enumerated()), id: \.element.id) { index, artist in
                            NavigationLink(destination: ArtistDetailView(artist: artist, rank: originalRanks[artist.id])) {
                                HStack(spacing: 10) {
                                    Text("#\(originalRanks[artist.id] ?? 0)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppStyles.accentColor)
                                        .frame(width: 30, alignment: .leading)
                                    
                                    LibraryRow.artist(artist)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .onAppear {
                                // Trigger loading more artists when reaching the end
                                loadMoreArtistsIfNeeded(currentItem: artist)
                            }
                        }
                        
                        // Loading indicator when fetching more artists
                        if isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                        }
                        
                        // "Load More" button when there are more artists and not searching
                        if displayedArtistCount < sortedArtists.count && !isLoadingMore && searchText.isEmpty {
                            Button(action: {
                                isLoadingMore = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    displayedArtistCount = min(displayedArtistCount + 75, sortedArtists.count)
                                    isLoadingMore = false
                                }
                            }) {
                                Text("Load More Artists")
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
                        
                        if filteredArtists.isEmpty && !searchText.isEmpty {
                            Text("No artists found matching '\(searchText)'")
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
