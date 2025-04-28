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
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading artists...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    List {
                        // Invisible anchor for scrolling to top with zero height
                        Text("")
                            .id("top")
                            .frame(height: 0)
                            .padding(0)
                            .opacity(0)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        
                        ForEach(musicLibrary.artists) { artist in
                            NavigationLink(destination: ArtistDetailView(artist: artist)) {
                                ArtistRow(artist: artist)
                            }
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

struct ArtistDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let artist: ArtistData
    
    // Helper function to format date
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Helper function to get unique album count
    private func albumCount() -> Int {
        return Set(artist.songs.compactMap { $0.albumTitle }).count
    }
    
    // Helper function to get most common genres
    private func topGenres(limit: Int = 3) -> [String] {
        var genreCounts: [String: Int] = [:]
        
        for song in artist.songs {
            if let genre = song.genre, !genre.isEmpty {
                genreCounts[genre, default: 0] += 1
            }
        }
        
        return genreCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
    
    // Helper function to get most played album
    private func mostPlayedAlbum() -> (title: String, playCount: Int) {
        var albumPlays: [String: Int] = [:]
        
        for song in artist.songs {
            if let album = song.albumTitle {
                albumPlays[album, default: 0] += (song.playCount ?? 0)
            }
        }
        
        if let topAlbum = albumPlays.max(by: { $0.value < $1.value }) {
            return (topAlbum.key, topAlbum.value)
        }
        
        return ("Unknown", 0)
    }
    
    // Helper function to get total duration of all songs
    private func totalDuration() -> String {
        let totalSeconds = artist.songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return String(format: "%dh %dm", hours, minutes)
    }
    
    // Helper function to get first and last added song dates
    private func dateRange() -> (first: Date?, last: Date?) {
        let dates = artist.songs.compactMap { $0.dateAdded }
        return (dates.min(), dates.max())
    }
    
    // Helper to calculate days between dates
    private func datesBetween(_ startDate: Date?, _ endDate: Date?) -> Int {
        guard let start = startDate, let end = endDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
    
    // Get album data for display
    private func albumData() -> [AlbumInfo] {
        // Group songs by album
        let songsByAlbum = Dictionary(grouping: artist.songs) { song in
            song.albumTitle ?? "Unknown"
        }
        
        // Convert to array of AlbumInfo
        return songsByAlbum.map { albumTitle, songs in
            let artwork = songs.first?.artwork
            let playCount = songs.reduce(0) { $0 + (($1.playCount ?? 0)) }
            
            return AlbumInfo(
                title: albumTitle,
                artwork: artwork,
                songCount: songs.count,
                playCount: playCount
            )
        }.sorted { $0.playCount > $1.playCount }
    }
    
    // Simple struct to hold album info for display
    private struct AlbumInfo: Identifiable {
        var id: String { title }
        let title: String
        let artwork: MPMediaItemArtwork?
        let songCount: Int
        let playCount: Int
    }
    
    var body: some View {
        List {
            // Artist header section
            Section(header: DetailHeaderView(
                title: artist.name,
                subtitle: "",
                plays: artist.totalPlayCount,
                songCount: artist.songs.count,
                artwork: artist.artwork,
                isAlbum: false,
                metadata: []
            )) {
                // Empty section content for spacing
            }
            
            // Songs section
            Section(header: Text("Songs").padding(.leading, -15)) {
                // Songs list sorted by play count with navigation
                ForEach(artist.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }, id: \.persistentID) { song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        SongRow(song: song)
                    }
                    .listRowSeparator(.hidden)
                }
            }
            
            // Albums section
            Section(header: Text("Albums").padding(.leading, -15)) {
                ForEach(albumData()) { album in
                    if let foundAlbum = musicLibrary.albums.first(where: { $0.title == album.title && $0.artist == artist.name }) {
                        NavigationLink(destination: AlbumDetailView(album: foundAlbum)) {
                            albumRow(album: album)
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        albumRow(album: album)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            
            // Artist Statistics section at the bottom
            Section(header: Text("Artist Statistics")
                .padding(.leading, -15)) {
                metadataRow(icon: "square.stack", title: "Albums", value: "\(albumCount())")
                    .listRowSeparator(.hidden)
                metadataRow(icon: "music.note.list", title: "Genres", value: topGenres().joined(separator: ", "))
                    .listRowSeparator(.hidden)
                metadataRow(icon: "clock", title: "Total Time", value: totalDuration())
                    .listRowSeparator(.hidden)
                metadataRow(icon: "plus.circle", title: "First Added", value: formatDate(dateRange().first))
                    .listRowSeparator(.hidden)
                
                let topAlbum = mostPlayedAlbum()
                metadataRow(icon: "star", title: "Top Album", value: topAlbum.title)
                    .listRowSeparator(.hidden)
                metadataRow(icon: "music.note.tv", title: "Album Plays", value: "\(topAlbum.playCount)")
                    .listRowSeparator(.hidden)
                
                // Average plays per song
                let avgPlays = artist.totalPlayCount / max(1, artist.songs.count)
                metadataRow(icon: "repeat", title: "Avg. Plays", value: "\(avgPlays) per song")
                    .listRowSeparator(.hidden)
                
                // Most recent addition
                if let lastAdded = dateRange().last {
                    metadataRow(icon: "calendar", title: "Last Added", value: formatDate(lastAdded))
                        .listRowSeparator(.hidden)
                }
                
                // Listening streak (if we had the data)
                metadataRow(icon: "chart.line.uptrend.xyaxis", title: "In Collection",
                           value: "\(datesBetween(dateRange().first, dateRange().last)) days")
                    .listRowSeparator(.hidden)
            }
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Row for an album in the albums list
    private func albumRow(album: AlbumInfo) -> some View {
        HStack {
            if let artwork = album.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "square.stack")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                Image(systemName: "square.stack")
                    .frame(width: 50, height: 50)
                    .background(AppStyles.secondaryColor)
                    .cornerRadius(AppStyles.cornerRadius)
            }
            
            VStack(alignment: .leading) {
                Text(album.title)
                    .font(AppStyles.bodyStyle)
                
                Text("\(album.songCount) songs")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(album.playCount) plays")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
    }
    
    private func metadataRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.secondary)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}
