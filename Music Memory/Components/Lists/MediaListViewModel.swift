// Music Memory/Components/Lists/MediaListViewModel.swift
import SwiftUI
import Combine

/// Generic view model that handles state and logic for all list views
class MediaListViewModel<T: MediaListDisplayable, SortOption: RawRepresentable & Hashable>: ObservableObject where SortOption.RawValue == String {
    // Published properties for view state
    @Published var items: [T] = []
    @Published var filteredItems: [T] = []
    @Published var searchText = ""
    @Published var sortOption: SortOption
    @Published var sortAscending = false
    @Published var isLoading = false
    @Published var displayedItemCount: Int
    @Published var isLoadingMore = false
    
    // Sort handlers dictionary
    private var sortHandlers: [SortOption: (T, T) -> Bool] = [:]
    
    // Cancellables for subscription management
    private var cancellables = Set<AnyCancellable>()
    
    init(initialSortOption: SortOption, batchSize: Int = 75) {
        self.sortOption = initialSortOption
        self.displayedItemCount = batchSize
        
        // Set up search and sort option publishers
        $searchText
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterItems()
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest3($items, $sortOption, $sortAscending)
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.applySort()
                self?.filterItems()
            }
            .store(in: &cancellables)
    }
    
    /// Register a sort handler for a specific sort option
    func registerSortHandler(for option: SortOption, handler: @escaping (T, T) -> Bool) {
        sortHandlers[option] = handler
    }
    
    /// Apply the current sort to items
    private func applySort() {
        if let sortHandler = sortHandlers[sortOption] {
            items.sort { item1, item2 in
                sortAscending ? !sortHandler(item1, item2) : sortHandler(item1, item2)
            }
        }
    }
    
    /// Filter items based on search text
    private func filterItems() {
        if searchText.isEmpty {
            filteredItems = Array(items.prefix(displayedItemCount))
        } else {
            filteredItems = items.filter { item in
                item.listTitle.localizedCaseInsensitiveContains(searchText) ||
                item.listSubtitle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    /// Load more items when scrolling to the end
    func loadMoreItems() {
        guard !isLoadingMore && displayedItemCount < items.count && searchText.isEmpty else {
            return
        }
        
        isLoadingMore = true
        
        // Simulate a small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            self.displayedItemCount = min(self.displayedItemCount + 75, self.items.count)
            self.filterItems()
            self.isLoadingMore = false
        }
    }
    
    /// Check if an item needs more items loaded
    func loadMoreIfNeeded(currentItem item: T) {
        guard let index = filteredItems.firstIndex(where: { $0.id == item.id }),
              index >= filteredItems.count - 15,
              displayedItemCount < items.count,
              !isLoadingMore,
              searchText.isEmpty else {
            return
        }
        
        loadMoreItems()
    }
    
    /// Reset the view when sort option or direction changes
    func resetView() {
        displayedItemCount = min(75, items.count)
        applySort()
        filterItems()
    }
}
