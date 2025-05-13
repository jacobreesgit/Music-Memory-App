// Music Memory/Views/Playlists/PlaylistsView.swift
import SwiftUI
import MediaPlayer

struct PlaylistsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @StateObject private var viewModel: MediaListViewModel<PlaylistData, PlaylistSortOption>
    
    // Initialize with default or specified sort options
    init(initialSortOption: PlaylistSortOption = .playCount, initialSortAscending: Bool = false) {
        let vm = MediaListViewModel<PlaylistData, PlaylistSortOption>(
            initialSortOption: initialSortOption,
            batchSize: 75
        )
        
        // Register sort handlers
        let factory = PlaylistsSortHandlerFactory()
        factory.registerSortHandlers(for: vm)
        
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        Group {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading playlists...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                MediaListView(
                    viewModel: viewModel,
                    emptyStateIcon: "music.note.list",
                    emptyStateTitle: "No playlists found in your library",
                    emptyStateMessage: "Playlists with play count information will appear here",
                    searchPlaceholder: "Search playlists",
                    loadMoreButtonText: "Load More Playlists"
                )
            }
        }
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Only load data if it hasn't been loaded yet
            if viewModel.items.isEmpty {
                viewModel.items = musicLibrary.filteredPlaylists
                viewModel.resetView()
            }
        }
        .onChange(of: musicLibrary.filteredPlaylists) { oldValue, newValue in
            // Update viewModel when the source data changes
            viewModel.items = newValue
            viewModel.resetView()
        }
    }
}
