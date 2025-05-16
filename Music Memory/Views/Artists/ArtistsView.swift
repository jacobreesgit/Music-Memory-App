import SwiftUI
import MediaPlayer

struct ArtistsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @StateObject private var viewModel: MediaListViewModel<ArtistData, ArtistSortOption>
    @StateObject private var navigationManager = NavigationManager.shared
    
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
                ZStack {
                    MediaListView(
                        viewModel: viewModel,
                        emptyStateIcon: "music.mic",
                        emptyStateTitle: "No artists found in your library",
                        emptyStateMessage: "Artists with play count information will appear here",
                        searchPlaceholder: "Search artists",
                        loadMoreButtonText: "Load More Artists"
                    )
                    
                    // Hidden navigation link that will be triggered programmatically
                    NavigationLink(
                        destination: navigationManager.navigateToArtist.map { ArtistDetailView(artist: $0) },
                        isActive: Binding(
                            get: { navigationManager.navigateToArtist != nil },
                            set: { if !$0 { navigationManager.navigateToArtist = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
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
            
            // Process any pending navigation
            navigationManager.processNavigation(using: musicLibrary)
        }
        .onChange(of: musicLibrary.filteredArtists) { oldValue, newValue in
            // Update viewModel when the source data changes
            viewModel.items = newValue
            viewModel.resetView()
        }
        .onDisappear {
            // Reset navigation when leaving the view
            navigationManager.navigateToArtist = nil
        }
    }
}
