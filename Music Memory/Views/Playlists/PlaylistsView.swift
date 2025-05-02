//
//  PlaylistsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//

import SwiftUI
import MediaPlayer

struct PlaylistsView: View {
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
    
    var filteredPlaylists: [PlaylistData] {
        if searchText.isEmpty {
            return sortedPlaylists
        } else {
            return sortedPlaylists.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var sortedPlaylists: [PlaylistData] {
        switch sortOption {
        case .playCount:
            return musicLibrary.filteredPlaylists.sorted {
                sortAscending ? $0.totalPlayCount < $1.totalPlayCount : $0.totalPlayCount > $1.totalPlayCount
            }
        case .name:
            return musicLibrary.filteredPlaylists.sorted {
                sortAscending ? $0.name < $1.name : $0.name > $1.name
            }
        case .songCount:
            return musicLibrary.filteredPlaylists.sorted {
                sortAscending ? $0.songs.count < $1.songs.count : $0.songs.count > $1.songs.count
            }
        }
    }
    
    private var originalRanks: [String: Int] {
        Dictionary(uniqueKeysWithValues: sortedPlaylists.enumerated().map { ($1.id, $0 + 1) })
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading playlists...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Updated Search and Sort Bar with sort direction
                SearchSortBar(
                    searchText: $searchText,
                    sortOption: $sortOption,
                    sortAscending: $sortAscending,
                    placeholder: "Search playlists"
                )

                if musicLibrary.filteredPlaylists.isEmpty {
                    // Show message when there are no playlists in the library
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                        
                        Text("No playlists found in your library")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Playlists with play count information will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(filteredPlaylists.enumerated()), id: \.element.id) { index, playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist, rank: originalRanks[playlist.id])) {
                                HStack(spacing: 10) {
                                    Text("#\(originalRanks[playlist.id] ?? 0)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppStyles.accentColor)
                                        .frame(width: 30, alignment: .leading)
                                    
                                    PlaylistRow(playlist: playlist)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                        
                        if filteredPlaylists.isEmpty && !searchText.isEmpty {
                            Text("No playlists found matching '\(searchText)'")
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
}
