//
//  SorterView.swift
//  Music Memory
//
//  Created by Jacob Rees on 07/05/2025.
//

import SwiftUI
import MediaPlayer

struct SorterView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    @State private var searchText = ""
    @State private var sortOption = SortOption.date
    @State private var sortAscending = false // Default to descending (newest first)
    @State private var sessionToDelete: SortSession? = nil
    @State private var showingDeleteAlert = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case date = "Date"
        case title = "Title"
        case source = "Source"
        
        var id: String { self.rawValue }
    }
    
    var filteredSessions: [SortSession] {
        if searchText.isEmpty {
            return sortedSessions
        } else {
            return sortedSessions.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.sourceName.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var sortedSessions: [SortSession] {
        switch sortOption {
        case .date:
            return sortSessionStore.sessions.sorted {
                sortAscending ? $0.date < $1.date : $0.date > $1.date
            }
        case .title:
            return sortSessionStore.sessions.sorted {
                sortAscending ? $0.title < $1.title : $0.title > $1.title
            }
        case .source:
            return sortSessionStore.sessions.sorted {
                sortAscending ? $0.sourceName < $1.sourceName : $0.sourceName > $1.sourceName
            }
        }
    }
    
    // Function to delete a specific session
    private func deleteSession(_ session: SortSession) {
        if let index = sortSessionStore.sessions.firstIndex(where: { $0.id == session.id }) {
            sortSessionStore.sessions.remove(at: index)
            sortSessionStore.saveSessions()
        }
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading your music...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Search and Sort Bar
                SearchSortBar(
                    searchText: $searchText,
                    sortOption: $sortOption,
                    sortAscending: $sortAscending,
                    placeholder: "Search sort sessions"
                )
                
                if sortSessionStore.sessions.isEmpty {
                    // Empty state view
                    VStack(spacing: 20) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                        
                        Text("No sorting sessions found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Sort your music to compare and rank songs in your library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Text("To get started, visit an album, artist, genre, or playlist and tap \"Sort Songs\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredSessions) { session in
                            NavigationLink(
                                destination: session.isComplete ?
                                    AnyView(SortResultsView(session: session)) :
                                    AnyView(SortSessionView(session: session))
                            ) {
                                SortSessionRow(session: session)
                            }
                            .contextMenu {
                                if session.isComplete {
                                    // For completed sessions, show "Delete Session"
                                    Button(role: .destructive, action: {
                                        sessionToDelete = session
                                        showingDeleteAlert = true
                                    }) {
                                        Label("Delete Sort Session", systemImage: "trash")
                                    }
                                } else {
                                    // For in-progress sessions, show "Discard"
                                    Button(role: .destructive, action: {
                                        sessionToDelete = session
                                        showingDeleteAlert = true
                                    }) {
                                        Label("Discard", systemImage: "xmark.circle")
                                    }
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: sortSessionStore.deleteSession)
                        
                        if filteredSessions.isEmpty && !searchText.isEmpty {
                            Text("No sessions found matching '\(searchText)'")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollDismissesKeyboard(.immediately)
                    .alert("Delete Sort Session?", isPresented: $showingDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            if let session = sessionToDelete {
                                deleteSession(session)
                            }
                        }
                    } message: {
                        Text(sessionToDelete?.isComplete ?? true ?
                             "This will permanently delete this song ranking. This action cannot be undone." :
                             "This will cancel your sorting progress. This action cannot be undone.")
                    }
                }
            }
            .navigationTitle("Sorter")
        }
    }
}

struct SortSessionRow: View {
    let session: SortSession
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork or placeholder
            if let artworkData = session.artworkData, let uiImage = UIImage(data: artworkData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                // Fallback to icon based on source type
                ZStack {
                    RoundedRectangle(cornerRadius: AppStyles.cornerRadius)
                        .fill(AppStyles.secondaryColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: iconForSource(session.source))
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }
            }
            
            // Title and source info
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(AppStyles.bodyStyle)
                    .lineLimit(1)
                
                Text(sourceDescription(session))
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Status info
            VStack(alignment: .trailing, spacing: 2) {
                if session.isComplete {
                    Text("\(session.sortedIDs.count) songs")
                        .font(AppStyles.playCountStyle)
                        .foregroundColor(AppStyles.accentColor)
                } else {
                    Text("\(Int(session.progress * 100))% complete")
                        .font(AppStyles.playCountStyle)
                        .foregroundColor(AppStyles.accentColor)
                }
                
                // Format date nicely
                Text(formattedDate(session.date))
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4) // Match existing row padding
    }
    
    // Helper to format the date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper to get icon based on source type
    private func iconForSource(_ source: SortSession.SortSource) -> String {
        switch source {
        case .album: return "square.stack"
        case .artist: return "music.mic"
        case .genre: return "music.note.list"
        case .playlist: return "list.bullet"
        }
    }
    
    // Helper to create source description
    private func sourceDescription(_ session: SortSession) -> String {
        let sourceType = sourceTypeString(session.source)
        return "From \(sourceType): \(session.sourceName)"
    }
    
    // Helper to get source type string
    private func sourceTypeString(_ source: SortSession.SortSource) -> String {
        switch source {
        case .album: return "Album"
        case .artist: return "Artist"
        case .genre: return "Genre"
        case .playlist: return "Playlist"
        }
    }
}
