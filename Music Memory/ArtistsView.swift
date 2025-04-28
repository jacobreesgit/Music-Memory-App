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
    @State private var refreshID = UUID()
    @State private var searchText = ""
    @State private var sortOption = SortOption.playCount
    
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
            return musicLibrary.artists.sorted { $0.totalPlayCount > $1.totalPlayCount }
        case .name:
            return musicLibrary.artists.sorted { $0.name < $1.name }
        case .songCount:
            return musicLibrary.artists.sorted { $0.songs.count > $1.songs.count }
        }
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading artists...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    // Search and Sort Bar
                    SearchSortBar(
                        searchText: $searchText,
                        sortOption: $sortOption,
                        placeholder: "Search artists"
                    )
                    
                    // Results count
                    if !searchText.isEmpty {
                        Text("Found \(filteredArtists.count) results")
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
                        
                        ForEach(filteredArtists) { artist in
                            NavigationLink(destination: ArtistDetailView(artist: artist)) {
                                ArtistRow(artist: artist)
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
                    .id(refreshID)
                    .listStyle(PlainListStyle())
                }
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                }
                .navigationTitle("Artists")
            }
        }
    }
}
