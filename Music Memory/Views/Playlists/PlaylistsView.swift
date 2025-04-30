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
    @State private var refreshID = UUID()
    @State private var searchText = ""
    @State private var sortOption = SortOption.playCount
    
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
            return musicLibrary.playlists.sorted { $0.totalPlayCount > $1.totalPlayCount }
        case .name:
            return musicLibrary.playlists.sorted { $0.name < $1.name }
        case .songCount:
            return musicLibrary.playlists.sorted { $0.songs.count > $1.songs.count }
        }
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading playlists...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    // Search and Sort Bar
                    SearchSortBar(
                        searchText: $searchText,
                        sortOption: $sortOption,
                        placeholder: "Search playlists"
                    )
                    
                    // Results count
                    if !searchText.isEmpty {
                        Text("Found \(filteredPlaylists.count) results")
                            .font(AppStyles.captionStyle)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                    }

                    List {
                        // Invisible anchor for scrolling to top
                        Text("")
                            .id("top")
                            .frame(height: 0)
                            .padding(0)
                            .opacity(0)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        
                        ForEach(filteredPlaylists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                PlaylistRow(playlist: playlist)
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
                    .id(refreshID)
                    .listStyle(PlainListStyle())
                }
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
    }
}
