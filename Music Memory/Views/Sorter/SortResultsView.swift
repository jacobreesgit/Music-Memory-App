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
    
    @State private var sortedItems: [Any] = []
    @State private var isSharePresented = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            // Header section with DetailHeaderView (consistent with other detail views)
            Section(header: VStack(alignment: .center, spacing: 4) {
                DetailHeaderView(
                    title: session.title,
                    subtitle: "\(sourceTypeString(session.source)): \(session.sourceName)",
                    plays: calculateTotalPlays(),
                    songCount: sortedItems.count,
                    artwork: artworkFromData(session.artworkData),
                    isAlbum: false,
                    metadata: [],
                    rank: nil
                )
            }) {
                // Empty section content for spacing
            }
            
            // Statistics section
            Section(header: Text("Statistics")
                .padding(.leading, -15)) {
                MetadataRow(icon: iconForContentType(), title: "Ranked Items", value: "\(sortedItems.count)")
                    .listRowSeparator(.hidden)
                
                MetadataRow(icon: "calendar", title: "Date Created", value: formatDate(session.date))
                    .listRowSeparator(.hidden)
                
                MetadataRow(icon: "arrow.up.arrow.down", title: "Source", value: "\(sourceTypeString(session.source)): \(session.sourceName)")
                    .listRowSeparator(.hidden)
                
                // Total play count across all items
                let totalPlays = calculateTotalPlays()
                MetadataRow(icon: "play.circle", title: "Total Plays", value: "\(totalPlays)")
                    .listRowSeparator(.hidden)
                
                // Total duration for songs
                if session.contentType == .songs {
                    let totalDuration = formatDuration(calculateTotalDuration())
                    MetadataRow(icon: "clock", title: "Total Duration", value: totalDuration)
                        .listRowSeparator(.hidden)
                }
            }
            
            // Results section - ranked items
            Section(header: Text("Ranking")
                .padding(.leading, -15)) {
                if sortedItems.isEmpty {
                    Text("Loading items...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(Array(sortedItems.enumerated()), id: \.offset) { index, item in
                        navigationLinkForItem(item, rank: index + 1)
                    }
                }
            }
        }
        .listSectionSpacing(0) // Match other detail views' section spacing
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline) // Consistent with other detail views
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { isSharePresented = true }) {
                        Label("Share Results", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Sort Session", systemImage: "trash")
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
            Text("This will permanently delete this ranking. This action cannot be undone.")
        }
        .onAppear {
            loadItems()
        }
    }
    
    // Helper to convert artwork data to MPMediaItemArtwork
    private func artworkFromData(_ data: Data?) -> MPMediaItemArtwork? {
        guard let artworkData = data, let uiImage = UIImage(data: artworkData) else {
            return nil
        }
        
        return MPMediaItemArtwork(boundsSize: uiImage.size) { _ in
            return uiImage
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
    
    // Helper to get icon based on content type
    private func iconForContentType() -> String {
        switch session.contentType {
        case .songs:
            return "music.note"
        case .albums:
            return "square.stack"
        case .artists:
            return "music.mic"
        case .genres:
            return "music.note.list"
        case .playlists:
            return "list.bullet"
        }
    }
    
    // Load items from IDs
    private func loadItems() {
        switch session.contentType {
        case .songs:
            loadSongs()
        case .albums:
            loadAlbums()
        case .artists:
            loadArtists()
        case .genres:
            loadGenres()
        case .playlists:
            loadPlaylists()
        }
    }
    
    // Load songs from persistent IDs
    private func loadSongs() {
        let songIDs = session.sortedIDs.compactMap { UInt64($0) }
        
        // Preserve the sorted order
        sortedItems = songIDs.compactMap { id in
            musicLibrary.songs.first { $0.persistentID == id }
        }
    }
    
    // Load albums from IDs
    private func loadAlbums() {
        let albumIDs = session.sortedIDs
        
        // Preserve the sorted order
        sortedItems = albumIDs.compactMap { id in
            musicLibrary.albums.first { $0.id == id }
        }
    }
    
    // Load artists from IDs
    private func loadArtists() {
        let artistIDs = session.sortedIDs
        
        // Preserve the sorted order
        sortedItems = artistIDs.compactMap { id in
            musicLibrary.artists.first { $0.id == id }
        }
    }
    
    // Load genres from IDs
    private func loadGenres() {
        let genreIDs = session.sortedIDs
        
        // Preserve the sorted order
        sortedItems = genreIDs.compactMap { id in
            musicLibrary.genres.first { $0.id == id }
        }
    }
    
    // Load playlists from IDs
    private func loadPlaylists() {
        let playlistIDs = session.sortedIDs
        
        // Preserve the sorted order
        sortedItems = playlistIDs.compactMap { id in
            musicLibrary.playlists.first { $0.id == id }
        }
    }
    
    // Calculate total plays based on content type
    private func calculateTotalPlays() -> Int {
        switch session.contentType {
        case .songs:
            return sortedItems.reduce(0) { $0 + ((($1 as? MPMediaItem)?.playCount) ?? 0) }
        case .albums:
            return sortedItems.reduce(0) { $0 + ((($1 as? AlbumData)?.totalPlayCount) ?? 0) }
        case .artists:
            return sortedItems.reduce(0) { $0 + ((($1 as? ArtistData)?.totalPlayCount) ?? 0) }
        case .genres:
            return sortedItems.reduce(0) { $0 + ((($1 as? GenreData)?.totalPlayCount) ?? 0) }
        case .playlists:
            return sortedItems.reduce(0) { $0 + ((($1 as? PlaylistData)?.totalPlayCount) ?? 0) }
        }
    }
    
    // Calculate total duration (only for songs)
    private func calculateTotalDuration() -> TimeInterval {
        if session.contentType == .songs {
            return sortedItems.reduce(0) { $0 + ((($1 as? MPMediaItem)?.playbackDuration) ?? 0) }
        }
        return 0
    }
    
    // Create the appropriate navigation link based on item type
    @ViewBuilder
    private func navigationLinkForItem(_ item: Any, rank: Int) -> some View {
        switch session.contentType {
        case .songs:
            if let song = item as? MPMediaItem {
                NavigationLink(destination: SongDetailView(song: song, rank: rank)) {
                    HStack(spacing: 10) {
                        Text("#\(rank)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .frame(width: 30, alignment: .leading)
                        
                        LibraryRow.song(song)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
        case .albums:
            if let album = item as? AlbumData {
                NavigationLink(destination: AlbumDetailView(album: album, rank: rank)) {
                    HStack(spacing: 10) {
                        Text("#\(rank)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .frame(width: 30, alignment: .leading)
                        
                        LibraryRow.album(album)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
        case .artists:
            if let artist = item as? ArtistData {
                NavigationLink(destination: ArtistDetailView(artist: artist, rank: rank)) {
                    HStack(spacing: 10) {
                        Text("#\(rank)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .frame(width: 30, alignment: .leading)
                        
                        LibraryRow.artist(artist)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
        case .genres:
            if let genre = item as? GenreData {
                NavigationLink(destination: GenreDetailView(genre: genre, rank: rank)) {
                    HStack(spacing: 10) {
                        Text("#\(rank)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .frame(width: 30, alignment: .leading)
                        
                        LibraryRow.genre(genre)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
        case .playlists:
            if let playlist = item as? PlaylistData {
                NavigationLink(destination: PlaylistDetailView(playlist: playlist, rank: rank)) {
                    HStack(spacing: 10) {
                        Text("#\(rank)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .frame(width: 30, alignment: .leading)
                        
                        LibraryRow.playlist(playlist)
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
    }
    
    // Generate text for sharing
    private func generateShareText() -> String {
        var typeName = ""
        switch session.contentType {
        case .songs: typeName = "Songs"
        case .albums: typeName = "Albums"
        case .artists: typeName = "Artists"
        case .genres: typeName = "Genres"
        case .playlists: typeName = "Playlists"
        }
        
        var text = "🎵 My Top \(typeName) from \(session.sourceName) 🎵\n\n"
        
        // Add sorted items
        for (index, item) in sortedItems.prefix(10).enumerated() {
            switch session.contentType {
            case .songs:
                if let song = item as? MPMediaItem {
                    text += "#\(index + 1): \(song.title ?? "Unknown") - \(song.artist ?? "Unknown")\n"
                }
            case .albums:
                if let album = item as? AlbumData {
                    text += "#\(index + 1): \(album.title) - \(album.artist)\n"
                }
            case .artists:
                if let artist = item as? ArtistData {
                    text += "#\(index + 1): \(artist.name)\n"
                }
            case .genres:
                if let genre = item as? GenreData {
                    text += "#\(index + 1): \(genre.name)\n"
                }
            case .playlists:
                if let playlist = item as? PlaylistData {
                    text += "#\(index + 1): \(playlist.name)\n"
                }
            }
        }
        
        // Add footer
        text += "\nRanked with Music Memory app"
        
        return text
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
