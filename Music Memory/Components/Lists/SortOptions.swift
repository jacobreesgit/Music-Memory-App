// Music Memory/Components/Lists/SortOptions.swift
import Foundation

/// Protocol for sort handler factories
protocol SortHandlerFactory {
    associatedtype T: MediaListDisplayable
    associatedtype SortOption: RawRepresentable & Hashable & CaseIterable & Identifiable where SortOption.RawValue == String
    
    /// Register sort handlers for a view model
    func registerSortHandlers(for viewModel: MediaListViewModel<T, SortOption>)
    
    /// Create a sort handler for a specific sort option
    func createSortHandler(for option: SortOption) -> ((T, T) -> Bool)?
}

// Base implementation
extension SortHandlerFactory {
    func registerSortHandlers(for viewModel: MediaListViewModel<T, SortOption>) {
        for option in SortOption.allCases {
            if let handler = createSortHandler(for: option) {
                viewModel.registerSortHandler(for: option, handler: handler)
            }
        }
    }
}
