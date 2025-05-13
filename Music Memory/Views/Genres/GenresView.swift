// Music Memory/Views/Genres/GenresView.swift
import SwiftUI
import MediaPlayer

struct GenresView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @StateObject private var viewModel: MediaListViewModel<GenreData, GenreSortOption>
    
    // Initialize with default or specified sort options
    init(initialSortOption: GenreSortOption = .playCount, initialSortAscending: Bool = false) {
        let vm = MediaListViewModel<GenreData, GenreSortOption>(
            initialSortOption: initialSortOption,
            batchSize: 75
        )
        
        // Register sort handlers
        let factory = GenresSortHandlerFactory()
        factory.registerSortHandlers(for: vm)
        
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        Group {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading genres...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                MediaListView(
                    viewModel: viewModel,
                    emptyStateIcon: "music.note.list",
                    emptyStateTitle: "No genres found in your library",
                    emptyStateMessage: "Genres with play count information will appear here",
                    searchPlaceholder: "Search genres",
                    loadMoreButtonText: "Load More Genres"
                )
            }
        }
        .navigationTitle("Genres")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Only load data if it hasn't been loaded yet
            if viewModel.items.isEmpty {
                viewModel.items = musicLibrary.filteredGenres
                viewModel.resetView()
            }
        }
        .onChange(of: musicLibrary.filteredGenres) { oldValue, newValue in
            // Update viewModel when the source data changes
            viewModel.items = newValue
            viewModel.resetView()
        }
    }
}
