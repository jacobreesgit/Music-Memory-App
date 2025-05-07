//
//  SortResultsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 07/05/2025.
//

import SwiftUI
import MediaPlayer
import UniformTypeIdentifiers

struct SortResultsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let session: SortSession
    
    @State private var sortedSongs = [MPMediaItem]()
    @State private var isSharePresented = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            // Header section
            Section {
                SortResultsHeaderView(session: session)
            }
            
            // Stats section
            Section(header: Text("Statistics")
                .padding(.leading, -15)) {
                MetadataRow(icon: "music.note.list", title: "Ranked Songs", value: "\(sortedSongs.count)")
                    .listRowSeparator(.hidden)
                
                MetadataRow(icon: "calendar", title: "Date Created", value: formatDate(session.date))
                    .listRowSeparator(.hidden)
                
                MetadataRow(icon: "arrow.up.arrow.down", title: "Source", value: "\(sourceTypeString(session.source)): \(session.sourceName)")
                    .listRowSeparator(.hidden)
                
                // Total play count across all songs
                let totalPlays = sortedSongs.reduce(0) { $0 + ($1.playCount ?? 0) }
                MetadataRow(icon: "play.circle", title: "Total Plays", value: "\(totalPlays)")
                    .listRowSeparator(.hidden)
                
                // Total duration
                let totalDuration = formatDuration(sortedSongs.reduce(0) { $0 + $1.playbackDuration })
                MetadataRow(icon: "clock", title: "Total Duration", value: totalDuration)
                    .listRowSeparator(.hidden)
            }
            
            // Results section - ranked songs
            Section(header: Text("Ranking")
                .padding(.leading, -15)) {
                if sortedSongs.isEmpty {
                    Text("Loading songs...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(Array(sortedSongs.enumerated()), id: \.element.persistentID) { index, song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            HStack(spacing: 10) {
                                Text("#\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 30, alignment: .leading)
                                
                                SongRow(song: song)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .navigationTitle(session.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { isSharePresented = true }) {
                        Label("Share Results", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Sort", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isSharePresented) {
            let text = generateShareText()
            ShareSheet(items: [text])
        }
        .alert("Delete Sort Session?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let index = sortSessionStore.sessions.firstIndex(where: { $0.id == session.id }) {
                    sortSessionStore.sessions.remove(at: index)
                    sortSessionStore.saveSessions()
                }
            }
        } message: {
            Text("This will permanently delete this song ranking. This action cannot be undone.")
        }
        .onAppear {
            loadSongs()
        }
    }
    
    // Helper to format the date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Helper to format duration
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // Helper for source type string
    private func sourceTypeString(_ source: SortSession.SortSource) -> String {
        switch source {
        case .album: return "Album"
        case .artist: return "Artist"
        case .genre: return "Genre"
        case .playlist: return "Playlist"
        }
    }
    
    // Load songs from persistent IDs
    private func loadSongs() {
        let songIDs = session.sortedIDs.compactMap { UInt64($0) }
        
        // Preserve the sorted order
        sortedSongs = songIDs.compactMap { id in
            musicLibrary.songs.first { $0.persistentID == id }
        }
    }
    
    // Generate text for sharing
    private func generateShareText() -> String {
        var text = "🎵 My Top Songs from \(session.sourceName) 🎵\n\n"
        
        // Add sorted songs
        for (index, song) in sortedSongs.prefix(10).enumerated() {
            text += "#\(index + 1): \(song.title ?? "Unknown") - \(song.artist ?? "Unknown")\n"
        }
        
        // Add footer
        text += "\nRanked with Music Memory app"
        
        return text
    }
}

// Header view for sort results
struct SortResultsHeaderView: View {
    let session: SortSession
    
    var body: some View {
        VStack(spacing: AppStyles.smallPadding) {
            // Artwork or placeholder
            if let artworkData = session.artworkData, let uiImage = UIImage(data: artworkData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                // Fallback to icon based on source type
                ZStack {
                    RoundedRectangle(cornerRadius: AppStyles.cornerRadius)
                        .fill(AppStyles.secondaryColor)
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: iconForSource(session.source))
                        .font(.system(size: 60))
                        .foregroundColor(.primary)
                }
            }
            
            // Title
            Text(session.title)
                .font(AppStyles.subtitleStyle)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            // Source
            Text("\(sourceTypeString(session.source)): \(session.sourceName)")
                .font(AppStyles.headlineStyle)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            // Date
            Text(formatDate(session.date))
                .font(AppStyles.captionStyle)
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // Helper to format the date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
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
    
    // Helper for source type string
    private func sourceTypeString(_ source: SortSession.SortSource) -> String {
        switch source {
        case .album: return "Album"
        case .artist: return "Artist"
        case .genre: return "Genre"
        case .playlist: return "Playlist"
        }
    }
}

// Helper for sharing content with the system share sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
