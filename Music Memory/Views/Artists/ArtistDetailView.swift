//
//  ArtistDetailView.swift
//  Music Memory
//
//  Created by Jacob Rees on 28/04/2025.
//

import SwiftUI
import MediaPlayer

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
            
            // Artist Statistics section
            Section(header: Text("Artist Statistics")
                .padding(.leading, -15)) {
                MetadataRow(icon: "square.stack", title: "Albums", value: "\(artist.albumCount)")
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "music.note.list", title: "Genres", value: artist.topGenres().joined(separator: ", "))
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "clock", title: "Total Time", value: totalDuration())
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "plus.circle", title: "First Added", value: formatDate(dateRange().first))
                    .listRowSeparator(.hidden)
                
                let topAlbums = albumData().prefix(1)
                if let topAlbum = topAlbums.first {
                    MetadataRow(icon: "star", title: "Top Album", value: topAlbum.title)
                        .listRowSeparator(.hidden)
                    MetadataRow(icon: "music.note.tv", title: "Album Plays", value: "\(topAlbum.playCount)")
                        .listRowSeparator(.hidden)
                }
                
                // Average plays per song
                MetadataRow(icon: "repeat", title: "Avg. Plays", value: "\(artist.averagePlayCount) per song")
                    .listRowSeparator(.hidden)
                
                // Most recent addition
                if let lastAdded = dateRange().last {
                    MetadataRow(icon: "calendar", title: "Last Added", value: formatDate(lastAdded))
                        .listRowSeparator(.hidden)
                }
                
                // Listening streak (if we had the data)
                MetadataRow(icon: "chart.line.uptrend.xyaxis", title: "In Collection",
                           value: "\(datesBetween(dateRange().first, dateRange().last)) days")
                    .listRowSeparator(.hidden)
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
}
