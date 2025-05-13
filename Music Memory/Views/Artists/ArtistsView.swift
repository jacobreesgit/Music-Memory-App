// Music Memory/Views/Artists/ArtistsView.swift
import SwiftUI
import MediaPlayer

struct ArtistsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @StateObject private var viewModel: MediaListViewModel<ArtistData, ArtistSortOption>
    
    // Initialize with default or specified sort options
    init(initialSortOption: ArtistSortOption = .playCount, initialSortAscending: Bool = false) {
        let vm = MediaListViewModel<ArtistData, ArtistSortOption>(
            initialSortOption: initialSortOption,
            batchSize: 75
        )
        
        // Register sort handlers
        let factory = ArtistsSortHandlerFactory()
        factory.registerSortHandlers(for: vm)
        
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        Group {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading artists...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                MediaListView(
                    viewModel: viewModel,
                    emptyStateIcon: "music.mic",
                    emptyStateTitle: "No artists found in your library",
                    emptyStateMessage: "Artists with play count information will appear here",
                    searchPlaceholder: "Search artists",
                    loadMoreButtonText: "Load More Artists"
                )
            }
        }
        .navigationTitle("Artists")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Only load data if it hasn't been loaded yet
            if viewModel.items.isEmpty {
                viewModel.items = musicLibrary.filteredArtists
                viewModel.resetView()
            }
        }
        .onChange(of: musicLibrary.filteredArtists) { oldValue, newValue in
            // Update viewModel when the source data changes
            viewModel.items = newValue
            viewModel.resetView()
        }
    }
}
