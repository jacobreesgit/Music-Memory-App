//
//  AlbumsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct AlbumsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var searchText = ""
    @State private var sortOption = SortOption.playCount
    @State private var sortAscending = false // Default to descending
    @State private var displayedAlbumCount = 75  // Start with 75 albums
    @State private var isLoadingMore = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case artist = "Artist"
        case dateAdded = "Date Added"
        case playCount = "Play Count"
        case recentlyPlayed = "Recently Played"
        case songCount = "Song Count"
        case title = "Title"
        
        var id: String { self.rawValue }
    }

    
    var filteredAlbums: [AlbumData] {
        if searchText.isEmpty {
            // When not searching, only show the current batch
            return Array(sortedAlbums.prefix(displayedAlbumCount))
        } else {
            // When searching, search through ALL albums
            return sortedAlbums.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.artist.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var sortedAlbums: [AlbumData] {
        switch sortOption {
        case .playCount:
            return musicLibrary.filteredAlbums.sorted {
                sortAscending ? $0.totalPlayCount < $1.totalPlayCount : $0.totalPlayCount > $1.totalPlayCount
            }
        case .title:
            return musicLibrary.filteredAlbums.sorted {
                sortAscending ? $0.title < $1.title : $0.title > $1.title
            }
        case .artist:
            return musicLibrary.filteredAlbums.sorted {
                sortAscending ? $0.artist < $1.artist : $0.artist > $1.artist
            }
        case .songCount:
            return musicLibrary.filteredAlbums.sorted {
                sortAscending ? $0.songs.count < $1.songs.count : $0.songs.count > $1.songs.count
            }
        case .dateAdded:
            return musicLibrary.filteredAlbums.sorted {
                // Get the most recent date added for each album
                let date0 = $0.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                return sortAscending ? date0 < date1 : date0 > date1
            }
        case .recentlyPlayed:
            return musicLibrary.filteredAlbums.sorted {
                // Get the most recent played date for each album
                let date0 = $0.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                return sortAscending ? date0 < date1 : date0 > date1
            }
        }
    }
    
    private var originalRanks: [String: Int] {
        Dictionary(uniqueKeysWithValues: sortedAlbums.enumerated().map { ($1.id, $0 + 1) })
    }
    
    // Function to load more albums when needed
    private func loadMoreAlbumsIfNeeded(currentItem item: AlbumData) {
        // Check if this is approaching the end of the displayed items
        if let index = filteredAlbums.firstIndex(where: { $0.id == item.id }),
           index >= filteredAlbums.count - 15, // Load when 15 items from end
           displayedAlbumCount < sortedAlbums.count,
           !isLoadingMore,
           searchText.isEmpty {  // Only load more when not searching
            
            isLoadingMore = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Load next batch
                displayedAlbumCount = min(displayedAlbumCount + 75, sortedAlbums.count)
                isLoadingMore = false
            }
        }
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading albums...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Updated Search and Sort Bar with sort direction
                SearchSortBar(
                    searchText: $searchText,
                    sortOption: $sortOption,
                    sortAscending: $sortAscending,
                    placeholder: "Search albums"
                )
                .padding(.top) // Added top padding to match other tabs
                .onChange(of: searchText) { oldValue, newValue in
                    // Reset batch loading when search text changes
                    if searchText.isEmpty {
                        displayedAlbumCount = min(75, sortedAlbums.count)
                    }
                }
                .onChange(of: sortOption) { oldValue, newValue in
                    // Reset batch loading when sort option changes
                    displayedAlbumCount = min(75, sortedAlbums.count)
                }
                .onChange(of: sortAscending) { oldValue, newValue in
                    // Reset batch loading when sort direction changes
                    displayedAlbumCount = min(75, sortedAlbums.count)
                }

                if musicLibrary.filteredAlbums.isEmpty {
                    // Show message when there are no albums in the library
                    VStack(spacing: 20) {
                        Image(systemName: "square.stack")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                        
                        Text("No albums found in your library")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Albums with play count information will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(filteredAlbums.enumerated()), id: \.element.id) { index, album in
                            NavigationLink(destination: AlbumDetailView(album: album, rank: originalRanks[album.id])) {
                                HStack(spacing: 10) {
                                    Text("#\(originalRanks[album.id] ?? 0)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppStyles.accentColor)
                                        .frame(width: 30, alignment: .leading)
                                    
                                    LibraryRow.album(album)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .onAppear {
                                // Trigger loading more albums when reaching the end
                                loadMoreAlbumsIfNeeded(currentItem: album)
                            }
                        }
                        
                        // Loading indicator when fetching more albums
                        if isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                        }
                        
                        // "Load More" button when there are more albums and not searching
                        if displayedAlbumCount < sortedAlbums.count && !isLoadingMore && searchText.isEmpty {
                            Button(action: {
                                isLoadingMore = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    displayedAlbumCount = min(displayedAlbumCount + 75, sortedAlbums.count)
                                    isLoadingMore = false
                                }
                            }) {
                                Text("Load More Albums")
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
                        
                        if filteredAlbums.isEmpty && !searchText.isEmpty {
                            Text("No albums found matching '\(searchText)'")
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
