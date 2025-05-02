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
    @State private var sortOption = SortOption.playCount
    @State private var sortAscending = false // Default to descending
    
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
            return musicLibrary.filteredGenres.sorted {
                sortAscending ? $0.songs.count < $1.songs.count : $0.songs.count > $1.songs.count
            }
        case .name:
            return musicLibrary.filteredGenres.sorted {
                sortAscending ? $0.name < $1.name : $0.name > $1.name
            }
        case .playCount:
            return musicLibrary.filteredGenres.sorted {
                sortAscending ? $0.totalPlayCount < $1.totalPlayCount : $0.totalPlayCount > $1.totalPlayCount
            }
        }
    }
    
    private var originalRanks: [String: Int] {
        Dictionary(uniqueKeysWithValues: sortedGenres.enumerated().map { ($1.id, $0 + 1) })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Updated Search and Sort Bar with sort direction
            SearchSortBar(
                searchText: $searchText,
                sortOption: $sortOption,
                sortAscending: $sortAscending,
                placeholder: "Search genres"
            )

            if musicLibrary.filteredGenres.isEmpty {
                // Show message when there are no genres in the library
                VStack(spacing: 20) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                    
                    Text("No genres found in your library")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Genres with play count information will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(filteredGenres.enumerated()), id: \.element.id) { index, genre in
                        NavigationLink(destination: GenreDetailView(genre: genre, rank: originalRanks[genre.id])) {
                            HStack(spacing: 10) {
                                Text("#\(originalRanks[genre.id] ?? 0)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 30, alignment: .leading)
                                
                                GenreRow(genre: genre)
                            }
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
}
