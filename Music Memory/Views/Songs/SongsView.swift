//
//  SongsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct SongsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var searchText = ""
    @State private var sortOption: SortOption
    @State private var sortAscending: Bool
    @State private var displayedSongCount = 50  // Start with 50 songs
    @State private var isLoadingMore = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case artist = "Artist"
        case dateAdded = "Date Added"
        case duration = "Duration"
        case playCount = "Play Count"
        case recentlyPlayed = "Recently Played"
        case title = "Title"
        
        var id: String { self.rawValue }
    }
    
    // Initialize with default or specified sort options
    init(initialSortOption: SortOption = .playCount, initialSortAscending: Bool = false) {
        _sortOption = State(initialValue: initialSortOption)
        _sortAscending = State(initialValue: initialSortAscending)
    }
    
    var filteredSongs: [MPMediaItem] {
        if searchText.isEmpty {
            // When not searching, only show the current batch
            return Array(sortedSongs.prefix(displayedSongCount))
        } else {
            // When searching, search through ALL songs
            return sortedSongs.filter {
                ($0.title?.lowercased().contains(searchText.lowercased()) ?? false) ||
                ($0.artist?.lowercased().contains(searchText.lowercased()) ?? false) ||
                ($0.albumTitle?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    var sortedSongs: [MPMediaItem] {
        var sorted: [MPMediaItem] = []
        
        switch sortOption {
        case .playCount:
            sorted = musicLibrary.filteredSongs.sorted {
                sortAscending ? $0.playCount < $1.playCount : $0.playCount > $1.playCount
            }
        case .title:
            sorted = musicLibrary.filteredSongs.sorted {
                sortAscending ? ($0.title ?? "") < ($1.title ?? "") : ($0.title ?? "") > ($1.title ?? "")
            }
        case .artist:
            sorted = musicLibrary.filteredSongs.sorted {
                sortAscending ? ($0.artist ?? "") < ($1.artist ?? "") : ($0.artist ?? "") > ($1.artist ?? "")
            }
        case .dateAdded:
            sorted = musicLibrary.filteredSongs.sorted {
                let date0 = $0.dateAdded
                let date1 = $1.dateAdded
                return sortAscending ? date0 < date1 : date0 > date1
            }
        case .duration:
            sorted = musicLibrary.filteredSongs.sorted {
                sortAscending ? $0.playbackDuration < $1.playbackDuration : $0.playbackDuration > $1.playbackDuration
            }
        case .recentlyPlayed:
            sorted = musicLibrary.filteredSongs.sorted {
                let date0 = $0.lastPlayedDate ?? .distantPast
                let date1 = $1.lastPlayedDate ?? .distantPast
                return sortAscending ? date0 < date1 : date0 > date1
            }
        }
        
        return sorted
    }
    
    private var originalRanks: [MPMediaEntityPersistentID: Int] {
        Dictionary(uniqueKeysWithValues: sortedSongs.enumerated().map { ($1.persistentID, $0 + 1) })
    }
    
    // Function to load more songs when needed
    private func loadMoreSongsIfNeeded(currentItem item: MPMediaItem) {
        // Check if this is approaching the end of the displayed items
        if let index = filteredSongs.firstIndex(where: { $0.persistentID == item.persistentID }),
           index >= filteredSongs.count - 15,
           displayedSongCount < sortedSongs.count,
           !isLoadingMore,
           searchText.isEmpty {  // Only load more when not searching
            
            isLoadingMore = true
            
            // Reduced delay from 0.5 to 0.2 seconds for faster response
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Increased batch size from 50 to 75 songs
                displayedSongCount = min(displayedSongCount + 75, sortedSongs.count)
                isLoadingMore = false
            }
        }
    }
    
    // MARK: - View Components
    
    // Loading state view
    @ViewBuilder
    private func loadingView() -> some View {
        LoadingView(message: "Loading songs...")
    }
    
    // Access required view
    @ViewBuilder
    private func accessRequiredView() -> some View {
        LibraryAccessView()
    }
    
    // Empty state view
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
                .padding(.top, 50)
            
            Text("No songs found in your library")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Songs with play count information will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Song row item
    @ViewBuilder
    private func songRowItem(song: MPMediaItem, rank: Int) -> some View {
        NavigationLink(destination: SongDetailView(song: song, rank: rank)) {
            HStack(spacing: 10) {
                Text("#\(rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppStyles.accentColor)
                    .frame(width: 30, alignment: .leading)
                
                // Use the unified LibraryRow component
                LibraryRow.song(song)
            }
        }
        .listRowSeparator(.hidden)
        .onAppear {
            loadMoreSongsIfNeeded(currentItem: song)
        }
    }
    
    // Loading more indicator
    @ViewBuilder
    private func loadingMoreIndicator() -> some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
        .listRowSeparator(.hidden)
    }
    
    // Load more button
    @ViewBuilder
    private func loadMoreButton() -> some View {
        Button(action: {
            isLoadingMore = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                displayedSongCount = min(displayedSongCount + 50, sortedSongs.count)
                isLoadingMore = false
            }
        }) {
            Text("Load More Songs")
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
    
    // No results message
    @ViewBuilder
    private func noResultsMessage() -> some View {
        Text("No songs found matching '\(searchText)'")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .listRowSeparator(.hidden)
    }
    
    // Main content list
    @ViewBuilder
    private func mainContentList() -> some View {
        List {
            ForEach(filteredSongs, id: \.persistentID) { song in
                songRowItem(song: song, rank: originalRanks[song.persistentID] ?? 0)
            }
            
            // Loading indicator when fetching more songs
            if isLoadingMore {
                loadingMoreIndicator()
            }
            
            // "Load More" button when there are more songs and not searching
            if displayedSongCount < sortedSongs.count && !isLoadingMore && searchText.isEmpty {
                loadMoreButton()
            }
            
            // No results message when searching
            if filteredSongs.isEmpty && !searchText.isEmpty {
                noResultsMessage()
            }
        }
        .listStyle(PlainListStyle())
        .scrollDismissesKeyboard(.immediately) // Dismiss keyboard when scrolling begins
    }
    
    // Search and Sort Controls
    @ViewBuilder
    private func searchAndSortControls() -> some View {
        SearchSortBar(
            searchText: $searchText,
            sortOption: $sortOption,
            sortAscending: $sortAscending,
            placeholder: "Search songs"
        )
        .padding(.top) // Added top padding to match other tabs
        .onChange(of: searchText) { _, _ in
            // Reset batch loading when search text changes
            if searchText.isEmpty {
                displayedSongCount = min(50, sortedSongs.count)
            }
        }
        .onChange(of: sortOption) { _, _ in
            // Reset batch loading when sort option changes
            displayedSongCount = min(50, sortedSongs.count)
        }
        .onChange(of: sortAscending) { _, _ in
            // Reset batch loading when sort direction changes
            displayedSongCount = min(50, sortedSongs.count)
        }
    }
    
    // Main body
    var body: some View {
        if musicLibrary.isLoading {
            loadingView()
        } else if !musicLibrary.hasAccess {
            accessRequiredView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Search and Sort Controls
                searchAndSortControls()

                // Main Content
                if musicLibrary.filteredSongs.isEmpty {
                    emptyStateView()
                } else {
                    mainContentList()
                }
            }
        }
    }
}
