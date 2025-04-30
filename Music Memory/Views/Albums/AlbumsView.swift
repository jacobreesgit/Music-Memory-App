//
//  AlbumsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

struct AlbumsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var refreshID = UUID()
    @State private var searchText = ""
    @State private var sortOption = SortOption.playCount
    
    enum SortOption: String, CaseIterable, Identifiable {
        case playCount = "Play Count"
        case title = "Title"
        case artist = "Artist"
        case songCount = "Song Count"
        
        var id: String { self.rawValue }
    }
    
    var filteredAlbums: [AlbumData] {
        if searchText.isEmpty {
            return sortedAlbums
        } else {
            return sortedAlbums.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.artist.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var sortedAlbums: [AlbumData] {
        switch sortOption {
        case .playCount:
            return musicLibrary.albums.sorted { $0.totalPlayCount > $1.totalPlayCount }
        case .title:
            return musicLibrary.albums.sorted { $0.title < $1.title }
        case .artist:
            return musicLibrary.albums.sorted { $0.artist < $1.artist }
        case .songCount:
            return musicLibrary.albums.sorted { $0.songs.count > $1.songs.count }
        }
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading albums...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    // Search and Sort Bar
                    SearchSortBar(
                        searchText: $searchText,
                        sortOption: $sortOption,
                        placeholder: "Search albums"
                    )
                    
                    // Results count
                    if !searchText.isEmpty {
                        Text("Found \(filteredAlbums.count) results")
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
                        
                        ForEach(filteredAlbums) { album in
                            NavigationLink(destination: AlbumDetailView(album: album)) {
                                AlbumRow(album: album)
                            }
                            .listRowSeparator(.hidden)
                        }
                        
                        if filteredAlbums.isEmpty && !searchText.isEmpty {
                            Text("No albums found matching '\(searchText)'")
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
