//
//  ReplaceView.swift
//  Music Memory
//
//  Created by Jacob Rees on 10/05/2025.
//

import SwiftUI
import MediaPlayer
import MusicKit

struct ReplaceView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @StateObject private var songVersionModel = SongVersionModel()
    
    @State private var isSearchingLibrary = false
    @State private var searchText = ""
    @State private var libraryItems: [MPMediaItem] = []
    @State private var filteredItems: [MPMediaItem] = []
    @State private var showingAuthorizationAlert = false
    @State private var showingPlaylistCreation = false
    
    var body: some View {
        VStack(spacing: 0) {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading your music...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else if !AppleMusicManager.shared.isAuthorized {
                appleAuthorizationView
            } else {
                mainReplaceView
            }
        }
        .navigationTitle("Replace")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Apple Music Required", isPresented: $showingAuthorizationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This feature requires a valid Apple Music subscription to access the full song catalog.")
        }
        .onAppear {
            // Use the library items from the music library model
            if libraryItems.isEmpty {
                libraryItems = musicLibrary.songs
                filterLibraryItems()
            }
        }
        .sheet(isPresented: $showingPlaylistCreation) {
            NavigationView {
                ReplacementPlaylistView(songVersionModel: songVersionModel)
                    .navigationTitle("Create Playlist")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingPlaylistCreation = false
                            }
                        }
                    }
            }
        }
    }
    
    private var appleAuthorizationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 50))
                .foregroundColor(AppStyles.accentColor)
                .padding(.top, 50)
            
            Text("Apple Music Subscription Required")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("This feature requires an active Apple Music subscription to find and suggest improved versions of your songs.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(AppStyles.accentColor)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mainReplaceView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search Header - Simplified to match SorterView structure
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search your library", text: $searchText)
                    .onChange(of: searchText) { _ in
                        filterLibraryItems()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        filterLibraryItems()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(AppStyles.secondaryColor)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top) // Added top padding to match Sorter tab
            
            // Songs list
            if filteredItems.isEmpty {
                VStack(spacing: 20) {
                    if searchText.isEmpty {
                        Text("No songs found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No songs match '\(searchText)'")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredItems, id: \.persistentID) { song in
                        NavigationLink(destination: SongVersionsView(librarySong: song, songVersionModel: songVersionModel)) {
                            HStack {
                                // Use LibraryRow instead of SongRow
                                LibraryRow.song(song)
                                
                                // Replacement badge if we have one
                                if songVersionModel.replacementMap[song] != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppStyles.accentColor)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    // Create Playlist button moved here to appear at the bottom when replacements exist
                    if !songVersionModel.replacementMap.isEmpty {
                        VStack {
                            Divider()
                            
                            Button(action: {
                                showingPlaylistCreation = true
                            }) {
                                HStack {
                                    Text("Create Playlist")
                                        .font(.headline)
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 14))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppStyles.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(AppStyles.cornerRadius)
                            }
                            .padding()
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private func filterLibraryItems() {
        var filtered = libraryItems
        
        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { song in
                (song.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (song.artist?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (song.albumTitle?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // No longer filter based on matched replacements since toggle is removed
        
        filteredItems = filtered
    }
}
