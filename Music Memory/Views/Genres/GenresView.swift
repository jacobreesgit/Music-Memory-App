//
//  GenresView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//

import SwiftUI
import MediaPlayer

struct GenresView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var searchText = ""
    @State private var sortOption = SortOption.songCount
    
    enum SortOption: String, CaseIterable, Identifiable {
        case songCount = "Song Count"
        case name = "Name"
        case playCount = "Play Count"
        
        var id: String { self.rawValue }
    }
    
    var filteredGenres: [GenreData] {
        if searchText.isEmpty {
            return sortedGenres
        } else {
            return sortedGenres.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var sortedGenres: [GenreData] {
        switch sortOption {
        case .songCount:
            return musicLibrary.genres.sorted { $0.songs.count > $1.songs.count }
        case .name:
            return musicLibrary.genres.sorted { $0.name < $1.name }
        case .playCount:
            return musicLibrary.genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search and Sort Bar
            SearchSortBar(
                searchText: $searchText,
                sortOption: $sortOption,
                placeholder: "Search genres"
            )
            
            // Results count
            if !searchText.isEmpty {
                Text("Found \(filteredGenres.count) results")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            List {
                ForEach(filteredGenres) { genre in
                    NavigationLink(destination: GenreDetailView(genre: genre)) {
                        GenreRow(genre: genre)
                    }
                    .listRowSeparator(.hidden)
                }
                
                if filteredGenres.isEmpty && !searchText.isEmpty {
                    Text("No genres found matching '\(searchText)'")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(PlainListStyle())
            .scrollDismissesKeyboard(.immediately) // Dismiss keyboard when scrolling begins
        }
    }
}
