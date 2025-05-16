import SwiftUI
import MediaPlayer

struct PlaylistsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @StateObject private var viewModel: MediaListViewModel<PlaylistData, PlaylistSortOption>
    @StateObject private var navigationManager = NavigationManager.shared
    
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
                ZStack {
                    MediaListView(
                        viewModel: viewModel,
                        emptyStateIcon: "music.note.list",
                        emptyStateTitle: "No playlists found in your library",
                        emptyStateMessage: "Playlists with play count information will appear here",
                        searchPlaceholder: "Search playlists",
                        loadMoreButtonText: "Load More Playlists"
                    )
                    
                    // Hidden navigation link that will be triggered programmatically
                    NavigationLink(
                        destination: navigationManager.navigateToPlaylist.map { PlaylistDetailView(playlist: $0) },
                        isActive: Binding(
                            get: { navigationManager.navigateToPlaylist != nil },
                            set: { if !$0 { navigationManager.navigateToPlaylist = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
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
            
            // Process any pending navigation
            navigationManager.processNavigation(using: musicLibrary)
        }
        .onChange(of: musicLibrary.filteredPlaylists) { oldValue, newValue in
            // Update viewModel when the source data changes
            viewModel.items = newValue
            viewModel.resetView()
        }
        .onDisappear {
            // Reset navigation when leaving the view
            navigationManager.navigateToPlaylist = nil
        }
    }
}
