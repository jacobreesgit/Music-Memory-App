//
//  GenresView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//

import SwiftUI
import MediaPlayer

struct GenresView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var searchText = ""
    @State private var sortOption = SortOption.playCount
    @State private var sortAscending = false // Default to descending
    @State private var displayedGenreCount = 75  // Start with 75 genres
    @State private var isLoadingMore = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case songCount = "Song Count"
        case name = "Name"
        case playCount = "Play Count"
        case dateAdded = "Recently Added"
        
        var id: String { self.rawValue }
    }
    
    var filteredGenres: [GenreData] {
        if searchText.isEmpty {
            // When not searching, only show the current batch
            return Array(sortedGenres.prefix(displayedGenreCount))
        } else {
            // When searching, search through ALL genres
            return sortedGenres.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var sortedGenres: [GenreData] {
        switch sortOption {
        case .songCount:
            return musicLibrary.filteredGenres.sorted {
                sortAscending ? $0.songs.count < $1.songs.count : $0.songs.count > $1.songs.count
            }
        case .name:
            return musicLibrary.filteredGenres.sorted {
                sortAscending ? $0.name < $1.name : $0.name > $1.name
            }
        case .playCount:
            return musicLibrary.filteredGenres.sorted {
                sortAscending ? $0.totalPlayCount < $1.totalPlayCount : $0.totalPlayCount > $1.totalPlayCount
            }
        case .dateAdded:
            return musicLibrary.filteredGenres.sorted {
                // Get the most recent date added for each genre
                let date0 = $0.songs.compactMap { $0.dateAdded }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { $1.dateAdded }.max() ?? Date.distantPast
                return sortAscending ? date0 < date1 : date0 > date1
            }
        }
    }
    
    private var originalRanks: [String: Int] {
        Dictionary(uniqueKeysWithValues: sortedGenres.enumerated().map { ($1.id, $0 + 1) })
    }
    
    // Function to load more genres when needed
    private func loadMoreGenresIfNeeded(currentItem item: GenreData) {
        // Check if this is approaching the end of the displayed items
        if let index = filteredGenres.firstIndex(where: { $0.id == item.id }),
           index >= filteredGenres.count - 15, // Load when 15 items from end
           displayedGenreCount < sortedGenres.count,
           !isLoadingMore,
           searchText.isEmpty {  // Only load more when not searching
            
            isLoadingMore = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Load next batch
                displayedGenreCount = min(displayedGenreCount + 75, sortedGenres.count)
                isLoadingMore = false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Updated Search and Sort Bar with sort direction
            SearchSortBar(
                searchText: $searchText,
                sortOption: $sortOption,
                sortAscending: $sortAscending,
                placeholder: "Search genres"
            )
            .padding(.top) // Added top padding to match other tabs
            .onChange(of: searchText) { _ in
                // Reset batch loading when search text changes
                if searchText.isEmpty {
                    displayedGenreCount = min(75, sortedGenres.count)
                }
            }
            .onChange(of: sortOption) { _ in
                // Reset batch loading when sort option changes
                displayedGenreCount = min(75, sortedGenres.count)
            }
            .onChange(of: sortAscending) { _ in
                // Reset batch loading when sort direction changes
                displayedGenreCount = min(75, sortedGenres.count)
            }

            if musicLibrary.filteredGenres.isEmpty {
                // Show message when there are no genres in the library
                VStack(spacing: 20) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                    
                    Text("No genres found in your library")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Genres with play count information will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(filteredGenres.enumerated()), id: \.element.id) { index, genre in
                        NavigationLink(destination: GenreDetailView(genre: genre, rank: originalRanks[genre.id])) {
                            HStack(spacing: 10) {
                                Text("#\(originalRanks[genre.id] ?? 0)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 30, alignment: .leading)
                                
                                GenreRow(genre: genre)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .onAppear {
                            // Trigger loading more genres when reaching the end
                            loadMoreGenresIfNeeded(currentItem: genre)
                        }
                    }
                    
                    // Loading indicator when fetching more genres
                    if isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    // "Load More" button when there are more genres and not searching
                    if displayedGenreCount < sortedGenres.count && !isLoadingMore && searchText.isEmpty {
                        Button(action: {
                            isLoadingMore = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                displayedGenreCount = min(displayedGenreCount + 75, sortedGenres.count)
                                isLoadingMore = false
                            }
                        }) {
                            Text("Load More Genres")
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
                    
                    if filteredGenres.isEmpty && !searchText.isEmpty {
                        Text("No genres found matching '\(searchText)'")
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
