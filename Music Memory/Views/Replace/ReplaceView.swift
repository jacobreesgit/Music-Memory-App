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
    @State private var showOnlyMatchedSongs = false
    @State private var includeRemixes = false
    @State private var showingPlaylistCreation = false
    @State private var selectedAnalysisMode: AnalysisMode = .manual
    @State private var batchProcessProgress: Double = 0
    @State private var libraryItems: [MPMediaItem] = []
    @State private var filteredItems: [MPMediaItem] = []
    @State private var showingAuthorizationAlert = false
    
    enum AnalysisMode: String, CaseIterable, Identifiable {
        case manual = "Manual"
        case automatic = "Automatic"
        
        var id: String { self.rawValue }
    }
    
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
        .alert("Apple Music Required", isPresented: $showingAuthorizationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This feature requires a valid Apple Music subscription to access the full song catalog.")
        }
        .onAppear {
            AppleMusicManager.shared.checkAuthorizationStatus()
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
            
            Text("Apple Music Access Required")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("This feature needs access to Apple Music to find and suggest improved versions of your songs.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Authorize Apple Music") {
                Task {
                    let status = await AppleMusicManager.shared.requestAuthorization()
                    
                    if status != .authorized {
                        // If not authorized, show alert
                        showingAuthorizationAlert = true
                    } else if !AppleMusicManager.shared.isSubscribed {
                        // If authorized but not subscribed, show alert
                        showingAuthorizationAlert = true
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(AppStyles.accentColor)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mainReplaceView: some View {
        VStack(spacing: 0) {
            // Search and Settings Header
            VStack(spacing: 8) {
                // Search bar
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
                
                // Filter and mode selection
                HStack {
                    // Analysis mode picker
                    Picker("Mode", selection: $selectedAnalysisMode) {
                        ForEach(AnalysisMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Spacer()
                    
                    // Only show matched songs toggle
                    Toggle(isOn: $showOnlyMatchedSongs) {
                        Text("Matched Only")
                            .font(.caption)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: AppStyles.accentColor))
                    .onChange(of: showOnlyMatchedSongs) { _ in
                        filterLibraryItems()
                    }
                }
                .padding(.horizontal)
                
                // Action buttons
                HStack {
                    // Create Playlist button - enabled if we have replacements
                    Button(action: {
                        showingPlaylistCreation = true
                    }) {
                        Label("Create Playlist", systemImage: "music.note.list")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(AppStyles.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(songVersionModel.replacementMap.isEmpty)
                    .opacity(songVersionModel.replacementMap.isEmpty ? 0.5 : 1.0)
                    
                    Spacer()
                    
                    // Analyze button - only in automatic mode
                    if selectedAnalysisMode == .automatic {
                        Button(action: {
                            Task {
                                await songVersionModel.processSongs(libraryItems, includeRemixes: includeRemixes)
                                filterLibraryItems()
                            }
                        }) {
                            Label("Analyze Library", systemImage: "chart.bar.doc.horizontal")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(songVersionModel.isProcessing)
                    }
                    
                    // Include remixes toggle
                    Toggle(isOn: $includeRemixes) {
                        Text("Include Remixes")
                            .font(.caption)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: AppStyles.accentColor))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Progress bar for batch processing
                if songVersionModel.isProcessing {
                    VStack(spacing: 4) {
                        ProgressView(value: Double(songVersionModel.processedItems), total: Double(songVersionModel.totalItems))
                            .progressViewStyle(LinearProgressViewStyle())
                            .tint(AppStyles.accentColor)
                        
                        Text("Analyzing \(songVersionModel.processedItems) of \(songVersionModel.totalItems) songs...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            
            Divider()
            
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
                        NavigationLink(destination: SongVersionsView(librarySong: song, songVersionModel: songVersionModel, includeRemixes: includeRemixes)) {
                            HStack {
                                // Song row
                                SongRow(song: song)
                                
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
        
        // Filter to only show songs with matched replacements if enabled
        if showOnlyMatchedSongs {
            filtered = filtered.filter { songVersionModel.replacementMap[$0] != nil }
        }
        
        filteredItems = filtered
    }
}
