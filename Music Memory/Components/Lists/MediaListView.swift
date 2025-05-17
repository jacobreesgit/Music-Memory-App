// Music Memory/Components/Lists/MediaListView.swift
import SwiftUI
import MediaPlayer

/// Reusable view container for all list views
struct MediaListView<T: MediaListDisplayable, SortOption: RawRepresentable & Hashable & CaseIterable & Identifiable>: View where SortOption.RawValue == String {
    // View model
    @ObservedObject var viewModel: MediaListViewModel<T, SortOption>
    
    // Environment
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    // Custom placeholders
    let emptyStateTitle: String
    let emptyStateMessage: String
    let searchPlaceholder: String
    let loadMoreButtonText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search and sort controls
            SearchSortBar(
                searchText: $viewModel.searchText,
                sortOption: $viewModel.sortOption,
                sortAscending: $viewModel.sortAscending,
                placeholder: searchPlaceholder
            )
            .padding(.top)
            .onChange(of: viewModel.searchText) { oldValue, newValue in
                if viewModel.searchText.isEmpty {
                    viewModel.resetView()
                }
            }
            .onChange(of: viewModel.sortOption) { oldValue, newValue in
                viewModel.resetView()
            }
            .onChange(of: viewModel.sortAscending) { oldValue, newValue in
                viewModel.resetView()
            }

            if viewModel.items.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Main content list
                listContentView
            }
        }
    }
    
    // Empty state view
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: iconForEmptyState())
                .font(.system(size: 50))
                .foregroundColor(.secondary)
                .padding(.top, 50)
            
            Text(emptyStateTitle)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // List content
    @ViewBuilder
    private var listContentView: some View {
        List {
            ForEach(viewModel.filteredItems) { item in
                NavigationLink(destination: item.createDetailView(rank: getRank(for: item))) {
                    HStack(spacing: 10) {
                        Text("#\(getRank(for: item))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .frame(width: 30, alignment: .leading)
                        
                        // Item row
                        itemRow(for: item)
                    }
                }
                .listRowSeparator(.hidden)
                .onAppear {
                    viewModel.loadMoreIfNeeded(currentItem: item)
                }
            }
            
            // Loading indicator
            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
            
            // Load more button
            if viewModel.displayedItemCount < viewModel.items.count && !viewModel.isLoadingMore && viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.loadMoreItems()
                }) {
                    Text(loadMoreButtonText)
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
            if viewModel.filteredItems.isEmpty && !viewModel.searchText.isEmpty {
                Text("No items found matching '\(viewModel.searchText)'")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .scrollDismissesKeyboard(.immediately)
    }
    
    // Item row view
    @ViewBuilder
    private func itemRow(for item: T) -> some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork or placeholder
            if let artwork = item.listArtwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: item.listIconName)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(item.useCircularArtwork ? 25 : AppStyles.cornerRadius)
            } else {
                if item.useCircularArtwork {
                    ZStack {
                        Circle()
                            .fill(AppStyles.secondaryColor)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: item.listIconName)
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppStyles.cornerRadius)
                            .fill(AppStyles.secondaryColor)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: item.listIconName)
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(item.listTitle)
                    .font(AppStyles.bodyStyle)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !item.listSubtitle.isEmpty {
                    Text(item.listSubtitle)
                        .font(AppStyles.captionStyle)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            // Play count
            Text("\(item.listPlayCount) plays")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
        .standardRowStyle()
    }
    
    // Get rank for an item (original position in sorted list)
    private func getRank(for item: T) -> Int {
        if let index = viewModel.items.firstIndex(where: { $0.id == item.id }) {
            return index + 1
        }
        return 0
    }
    
    // Icon for empty state
    private func iconForEmptyState() -> String {
        guard let sampleItem = viewModel.items.first else {
            return "music.note"
        }
        return sampleItem.listIconName
    }
}

// Convenience initializer with defaults
extension MediaListView {
    init(
        viewModel: MediaListViewModel<T, SortOption>,
        emptyStateIcon: String = "music.note",
        emptyStateTitle: String = "No items found",
        emptyStateMessage: String = "Items with play count information will appear here",
        searchPlaceholder: String = "Search",
        loadMoreButtonText: String = "Load More"
    ) {
        self.viewModel = viewModel
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
        self.searchPlaceholder = searchPlaceholder
        self.loadMoreButtonText = loadMoreButtonText
    }
}
