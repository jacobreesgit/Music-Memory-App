//
//  SearchSortBar.swift
//  Music Memory
//
//  Created by Jacob Rees on 28/04/2025.
//

import SwiftUI

struct SearchSortBar<SortType: Identifiable & CaseIterable>: View where SortType: RawRepresentable, SortType.RawValue == String {
    @Binding var searchText: String
    @Binding var sortOption: SortType
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
                        sortOption = option
                    }) {
                        HStack {
                            Text(option.rawValue)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
                    .foregroundColor(AppStyles.accentColor)
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
