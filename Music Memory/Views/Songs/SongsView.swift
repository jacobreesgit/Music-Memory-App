// Music Memory/Views/Songs/SongsView.swift
import SwiftUI
import MediaPlayer

struct SongsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @StateObject private var viewModel: MediaListViewModel<MPMediaItem, SongSortOption>
    
    // Initialize with default or specified sort options
    init(initialSortOption: SongSortOption = .playCount, initialSortAscending: Bool = false) {
        let vm = MediaListViewModel<MPMediaItem, SongSortOption>(
            initialSortOption: initialSortOption,
            batchSize: 50
        )
        
        // Register sort handlers
        let factory = SongsSortHandlerFactory()
        factory.registerSortHandlers(for: vm)
        
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        Group {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading songs...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                MediaListView(
                    viewModel: viewModel,
                    emptyStateIcon: "music.note",
                    emptyStateTitle: "No songs found in your library",
                    emptyStateMessage: "Songs with play count information will appear here",
                    searchPlaceholder: "Search songs",
                    loadMoreButtonText: "Load More Songs"
                )
            }
        }
        .navigationTitle("Songs")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Only load data if it hasn't been loaded yet
            if viewModel.items.isEmpty {
                viewModel.items = musicLibrary.filteredSongs
                viewModel.resetView()
            }
        }
        .onChange(of: musicLibrary.filteredSongs) { oldValue, newValue in
            // Update viewModel when the source data changes
            viewModel.items = newValue
            viewModel.resetView()
        }
    }
}
