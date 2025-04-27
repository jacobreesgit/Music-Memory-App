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
    
    var body: some View {
        NavigationView {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading artists...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                List(musicLibrary.artists) { artist in
                    NavigationLink(destination: ArtistDetailView(artist: artist)) {
                        ArtistRow(artist: artist)
                    }
                }
                .navigationTitle("Artists by Plays")
            }
        }
    }
}

struct ArtistDetailView: View {
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
    
    var body: some View {
        List {
            // Artist header with metadata
            Section(header: DetailHeaderView(
                title: artist.name,
                subtitle: "",
                plays: artist.totalPlayCount,
                songCount: artist.songs.count,
                artwork: artist.artwork,
                isAlbum: false,
                metadata: []
            )) {
                // Songs list sorted by play count
                ForEach(artist.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }, id: \.persistentID) { song in
                    SongRow(song: song)
                }
            }
            
            // Additional artist statistics section
            Section(header: Text("Artist Statistics")
                .padding(.leading, -15)) {
                metadataRow(icon: "square.stack", title: "Albums", value: "\(albumCount())")
                metadataRow(icon: "music.note.list", title: "Genres", value: topGenres().joined(separator: ", "))
                metadataRow(icon: "clock", title: "Total Time", value: totalDuration())
                metadataRow(icon: "plus.circle", title: "First Added", value: formatDate(dateRange().first))
                
                let topAlbum = mostPlayedAlbum()
                metadataRow(icon: "star", title: "Top Album", value: topAlbum.title)
                metadataRow(icon: "music.note.tv", title: "Album Plays", value: "\(topAlbum.playCount)")
                
                // Average plays per song
                let avgPlays = artist.totalPlayCount / max(1, artist.songs.count)
                metadataRow(icon: "repeat", title: "Avg. Plays", value: "\(avgPlays) per song")
                
                // Most recent addition
                if let lastAdded = dateRange().last {
                    metadataRow(icon: "calendar", title: "Last Added", value: formatDate(lastAdded))
                }
                
                // Listening streak (if we had the data)
                metadataRow(icon: "chart.line.uptrend.xyaxis", title: "In Collection",
                           value: "\(datesBetween(dateRange().first, dateRange().last)) days")
            }
            
            // Albums by this artist
            Section(header: Text("Albums")
                .padding(.leading, -15)) {
                // Group songs by album and show album rows
                ForEach(albumsByPlayCount(), id: \.title) { album in
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
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper to calculate days between dates
    private func datesBetween(_ startDate: Date?, _ endDate: Date?) -> Int {
        guard let start = startDate, let end = endDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
    
    // Helper to get albums by play count
    private func albumsByPlayCount() -> [(title: String, artwork: MPMediaItemArtwork?, songCount: Int, playCount: Int)] {
        var albumsData: [String: (artwork: MPMediaItemArtwork?, songs: [MPMediaItem], playCount: Int)] = [:]
        
        // Group songs by album
        for song in artist.songs {
            if let albumTitle = song.albumTitle {
                if var album = albumsData[albumTitle] {
                    album.songs.append(song)
                    album.playCount += (song.playCount ?? 0)
                    albumsData[albumTitle] = album
                } else {
                    albumsData[albumTitle] = (song.artwork, [song], song.playCount ?? 0)
                }
            }
        }
        
        // Convert to sorted array
        return albumsData.map { (title: $0.key,
                                 artwork: $0.value.artwork,
                                 songCount: $0.value.songs.count,
                                 playCount: $0.value.playCount) }
            .sorted { $0.playCount > $1.playCount }
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
