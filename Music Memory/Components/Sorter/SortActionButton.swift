//
//  SortActionButton.swift
//  Music Memory
//
//  Created by Jacob Rees on 08/05/2025.
//

import SwiftUI
import MediaPlayer

struct SortActionButton<T>: View {
    @EnvironmentObject var sortSessionStore: SortSessionStore
    
    // Required properties
    let title: String
    let items: [T]
    let source: SortSession.SortSource
    let sourceID: String
    let sourceName: String
    let contentType: SortSession.ContentType
    let artwork: MPMediaItemArtwork?
    
    // Navigation state
    @State private var isNavigatingToSortSession = false
    @State private var navigatingSortSession = SortSession(
        title: "",
        songs: [],
        source: .album,
        sourceID: "",
        sourceName: ""
    )
    
    var body: some View {
        Button(action: {
            createSortSession()
        }) {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(AppStyles.accentColor.gradient)
            .cornerRadius(AppStyles.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 0)
        .background(
            NavigationLink(
                destination: SortSessionView(session: navigatingSortSession),
                isActive: $isNavigatingToSortSession,
                label: { EmptyView() }
            )
            .opacity(0)
        )
        .listRowBackground(Color(UIColor.systemGroupedBackground)) // Match system background
        .listRowInsets(EdgeInsets()) // Remove default insets
        .listRowSeparator(.hidden)
    }
    
    // Create a sort session based on the content type
    private func createSortSession() {
        switch contentType {
        case .songs:
            if let songs = items as? [MPMediaItem] {
                navigatingSortSession = SortSession(
                    title: "Sort: \(title)",
                    songs: songs,
                    source: source,
                    sourceID: sourceID,
                    sourceName: sourceName,
                    artwork: artwork
                )
            }
            
        case .albums:
            if let albums = items as? [AlbumData] {
                navigatingSortSession = SortSession(
                    title: "Sort: \(title)",
                    albums: albums,
                    source: source,
                    sourceID: sourceID,
                    sourceName: sourceName,
                    artwork: artwork
                )
            }
            
        case .artists:
            if let artists = items as? [ArtistData] {
                navigatingSortSession = SortSession(
                    title: "Sort: \(title)",
                    artists: artists,
                    source: source,
                    sourceID: sourceID,
                    sourceName: sourceName,
                    artwork: artwork
                )
            }
            
        case .genres:
            if let genres = items as? [GenreData] {
                navigatingSortSession = SortSession(
                    title: "Sort: \(title)",
                    genres: genres,
                    source: source,
                    sourceID: sourceID,
                    sourceName: sourceName,
                    artwork: artwork
                )
            }
            
        case .playlists:
            if let playlists = items as? [PlaylistData] {
                navigatingSortSession = SortSession(
                    title: "Sort: \(title)",
                    playlists: playlists,
                    source: source,
                    sourceID: sourceID,
                    sourceName: sourceName,
                    artwork: artwork
                )
            }
        }
        
        // Add to session store
        sortSessionStore.addSession(navigatingSortSession)
        
        // Navigate to sorting interface
        isNavigatingToSortSession = true
    }
}
