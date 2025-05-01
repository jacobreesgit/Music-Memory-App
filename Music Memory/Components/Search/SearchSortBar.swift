//
//  SearchSortBar.swift
//  Music Memory
//
//  Created by Jacob Rees on 28/04/2025.
//

import SwiftUI

/// A reusable search and sort bar for collection views
struct SearchSortBar<SortType: Identifiable & CaseIterable>: View where SortType: RawRepresentable, SortType.RawValue == String {
    @Binding var searchText: String
    @Binding var sortOption: SortType
    @Binding var sortAscending: Bool
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $searchText)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .frame(height: 16)
            
            Menu {
                ForEach(Array(SortType.allCases as! [SortType])) { option in
                    Button(action: {
                        // If selecting the same option, toggle direction
                        if sortOption == option {
                            sortAscending.toggle()
                        } else {
                            // New option - set to default (descending)
                            sortOption = option
                            sortAscending = false
                        }
                    }) {
                        HStack {
                            Text(option.rawValue)
                            if sortOption == option {
                                Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(sortOption.rawValue)
                        .foregroundColor(AppStyles.accentColor)
                    
                    // Show chevron indicating current sort direction
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppStyles.accentColor)
                }
            }
        }
        .padding(10)
        .background(AppStyles.secondaryColor)
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

// Added initializer with default parameter for backward compatibility
extension SearchSortBar {
    init(searchText: Binding<String>, sortOption: Binding<SortType>, placeholder: String) {
        self._searchText = searchText
        self._sortOption = sortOption
        self._sortAscending = .constant(false) // Default to descending
        self.placeholder = placeholder
    }
}
