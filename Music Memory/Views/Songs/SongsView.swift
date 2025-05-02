//
//  SongsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct SongsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var searchText = ""
    @State private var sortOption = SortOption.playCount
    @State private var sortAscending = false // Default to descending
    
    enum SortOption: String, CaseIterable, Identifiable {
        case playCount = "Play Count"
        case title = "Title"
        case artist = "Artist"
        case dateAdded = "Date Added"
        case duration = "Duration"
        
        var id: String { self.rawValue }
    }
    
    var filteredSongs: [MPMediaItem] {
        if searchText.isEmpty {
            return sortedSongs
        } else {
            return sortedSongs.filter {
                ($0.title?.lowercased().contains(searchText.lowercased()) ?? false) ||
                ($0.artist?.lowercased().contains(searchText.lowercased()) ?? false) ||
                ($0.albumTitle?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    var sortedSongs: [MPMediaItem] {
        var sorted: [MPMediaItem] = []
        
        switch sortOption {
        case .playCount:
            sorted = musicLibrary.filteredSongs.sorted {
                sortAscending ? ($0.playCount ?? 0) < ($1.playCount ?? 0) : ($0.playCount ?? 0) > ($1.playCount ?? 0)
            }
        case .title:
            sorted = musicLibrary.filteredSongs.sorted {
                sortAscending ? ($0.title ?? "") < ($1.title ?? "") : ($0.title ?? "") > ($1.title ?? "")
            }
        case .artist:
            sorted = musicLibrary.filteredSongs.sorted {
                sortAscending ? ($0.artist ?? "") < ($1.artist ?? "") : ($0.artist ?? "") > ($1.artist ?? "")
            }
        case .dateAdded:
            sorted = musicLibrary.filteredSongs.sorted {
                let date0 = $0.dateAdded ?? Date.distantPast
                let date1 = $1.dateAdded ?? Date.distantPast
                return sortAscending ? date0 < date1 : date0 > date1
            }
        case .duration:
            sorted = musicLibrary.filteredSongs.sorted {
                sortAscending ? $0.playbackDuration < $1.playbackDuration : $0.playbackDuration > $1.playbackDuration
            }
        }
        
        return sorted
    }
    
    private var originalRanks: [MPMediaEntityPersistentID: Int] {
        Dictionary(uniqueKeysWithValues: sortedSongs.enumerated().map { ($1.persistentID, $0 + 1) })
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading songs...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Updated Search and Sort Bar with sort direction
                SearchSortBar(
                    searchText: $searchText,
                    sortOption: $sortOption,
                    sortAscending: $sortAscending,
                    placeholder: "Search songs"
                )

                // List with content
                if musicLibrary.filteredSongs.isEmpty {
                    // Show message when there are no songs in the library
                    VStack(spacing: 20) {
                        Image(systemName: "music.note")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                        
                        Text("No songs found in your library")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Songs with play count information will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(filteredSongs.enumerated()), id: \.element.persistentID) { index, song in
                            NavigationLink(destination: SongDetailView(song: song, rank: originalRanks[song.persistentID])) {
                                HStack(spacing: 10) {
                                    Text("#\(originalRanks[song.persistentID] ?? 0)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppStyles.accentColor)
                                        .frame(width: 30, alignment: .leading)
                                    
                                    SongRow(song: song)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                        
                        if filteredSongs.isEmpty && !searchText.isEmpty {
                            Text("No songs found matching '\(searchText)'")
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
