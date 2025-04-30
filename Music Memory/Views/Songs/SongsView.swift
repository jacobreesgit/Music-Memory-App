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
        switch sortOption {
        case .playCount:
            return musicLibrary.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }
        case .title:
            return musicLibrary.songs.sorted { ($0.title ?? "") < ($1.title ?? "") }
        case .artist:
            return musicLibrary.songs.sorted { ($0.artist ?? "") < ($1.artist ?? "") }
        case .dateAdded:
            return musicLibrary.songs.sorted { ($0.dateAdded ?? Date.distantPast) > ($1.dateAdded ?? Date.distantPast) }
        case .duration:
            return musicLibrary.songs.sorted { $0.playbackDuration > $1.playbackDuration }
        }
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading songs...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Search and Sort Bar
                SearchSortBar(
                    searchText: $searchText,
                    sortOption: $sortOption,
                    placeholder: "Search songs"
                )
                
                // Results count
                if !searchText.isEmpty {
                    Text("Found \(filteredSongs.count) results")
                        .font(AppStyles.captionStyle)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                }

                // List with content
                List {
                    ForEach(filteredSongs, id: \.persistentID) { song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            SongRow(song: song)
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
