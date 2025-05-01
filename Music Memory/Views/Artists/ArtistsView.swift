//
//  ArtistsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct ArtistsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var searchText = ""
    @State private var sortOption = SortOption.playCount
    @State private var sortAscending = false // Default to descending
    
    enum SortOption: String, CaseIterable, Identifiable {
        case playCount = "Play Count"
        case name = "Name"
        case songCount = "Song Count"
        
        var id: String { self.rawValue }
    }
    
    var filteredArtists: [ArtistData] {
        if searchText.isEmpty {
            return sortedArtists
        } else {
            return sortedArtists.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var sortedArtists: [ArtistData] {
        switch sortOption {
        case .playCount:
            return musicLibrary.artists.sorted {
                sortAscending ? $0.totalPlayCount < $1.totalPlayCount : $0.totalPlayCount > $1.totalPlayCount
            }
        case .name:
            return musicLibrary.artists.sorted {
                sortAscending ? $0.name < $1.name : $0.name > $1.name
            }
        case .songCount:
            return musicLibrary.artists.sorted {
                sortAscending ? $0.songs.count < $1.songs.count : $0.songs.count > $1.songs.count
            }
        }
    }
    
    private var originalRanks: [String: Int] {
        Dictionary(uniqueKeysWithValues: sortedArtists.enumerated().map { ($1.id, $0 + 1) })
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading artists...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Updated Search and Sort Bar with sort direction
                SearchSortBar(
                    searchText: $searchText,
                    sortOption: $sortOption,
                    sortAscending: $sortAscending,
                    placeholder: "Search artists"
                )

                List {
                    ForEach(Array(filteredArtists.enumerated()), id: \.element.id) { index, artist in
                        NavigationLink(destination: ArtistDetailView(artist: artist, rank: originalRanks[artist.id])) {
                            HStack(spacing: 10) {
                                Text("#\(originalRanks[artist.id] ?? 0)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 30, alignment: .leading)
                                
                                ArtistRow(artist: artist)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    if filteredArtists.isEmpty && !searchText.isEmpty {
                        Text("No artists found matching '\(searchText)'")
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
