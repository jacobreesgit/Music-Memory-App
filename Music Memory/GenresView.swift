//
//  GenresView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//


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
    @State private var refreshID = UUID()
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
        ScrollViewReader { proxy in
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
                    // Invisible anchor for scrolling to top
                    Text("")
                        .id("top")
                        .frame(height: 0)
                        .padding(0)
                        .opacity(0)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    
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
                .id(refreshID)
                .listStyle(PlainListStyle())
            }
            .onAppear {
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }
}

// Genre row for displaying in lists
struct GenreRow: View {
    let genre: GenreData
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork or placeholder
            if let artwork = genre.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "music.note.list")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: AppStyles.cornerRadius)
                        .fill(AppStyles.secondaryColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(genre.name)
                    .font(AppStyles.bodyStyle)
                    .lineLimit(1)
                
                Text("\(genre.songs.count) songs")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text("\(genre.totalPlayCount) plays")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
        .padding(.vertical, 4)
    }
}