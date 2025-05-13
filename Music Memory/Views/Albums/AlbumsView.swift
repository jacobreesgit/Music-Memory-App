// Music Memory/Views/Albums/AlbumsView.swift
import SwiftUI
import MediaPlayer

struct AlbumsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @StateObject private var viewModel: MediaListViewModel<AlbumData, AlbumSortOption>
    
    // Initialize with default or specified sort options
    init(initialSortOption: AlbumSortOption = .playCount, initialSortAscending: Bool = false) {
        let vm = MediaListViewModel<AlbumData, AlbumSortOption>(
            initialSortOption: initialSortOption,
            batchSize: 75
        )
        
        // Register sort handlers
        let factory = AlbumsSortHandlerFactory()
        factory.registerSortHandlers(for: vm)
        
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        Group {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading albums...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                MediaListView(
                    viewModel: viewModel,
                    emptyStateIcon: "square.stack",
                    emptyStateTitle: "No albums found in your library",
                    emptyStateMessage: "Albums with play count information will appear here",
                    searchPlaceholder: "Search albums",
                    loadMoreButtonText: "Load More Albums"
                )
            }
        }
        .navigationTitle("Albums")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Only load data if it hasn't been loaded yet
            if viewModel.items.isEmpty {
                viewModel.items = musicLibrary.filteredAlbums
                viewModel.resetView()
            }
        }
        .onChange(of: musicLibrary.filteredAlbums) { oldValue, newValue in
            // Update viewModel when the source data changes
            viewModel.items = newValue
            viewModel.resetView()
        }
    }
}
