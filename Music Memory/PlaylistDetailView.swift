//
//  PlaylistDetailView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//

import SwiftUI
import MediaPlayer

struct PlaylistDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let playlist: PlaylistData
    
    // Helper function to format date
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Helper function to format total duration
    private func totalDuration() -> String {
        let totalSeconds = playlist.songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Helper function to get most common genres
    private func topGenres(limit: Int = 3) -> [String] {
        var genreCounts: [String: Int] = [:]
        
        for song in playlist.songs {
            if let genre = song.genre, !genre.isEmpty {
                genreCounts[genre, default: 0] += 1
            }
        }
        
        return genreCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
    
    // Helper function to get top artists sorted by PLAY COUNT (not song count)
    private func topArtists(limit: Int = 3) -> [(name: String, songCount: Int, playCount: Int)] {
        var artistSongCounts: [String: Int] = [:]
        var artistPlayCounts: [String: Int] = [:]
        
        for song in playlist.songs {
            if let artist = song.artist, !artist.isEmpty {
                artistSongCounts[artist, default: 0] += 1
                artistPlayCounts[artist, default: 0] += (song.playCount ?? 0)
            }
        }
        
        // Return top artists sorted by play count
        return artistPlayCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, artistSongCounts[$0.key, default: 0], $0.value) }
    }
    
    // Helper function to get unique albums count
    private func uniqueAlbums() -> Int {
        return Set(playlist.songs.compactMap { $0.albumTitle }).count
    }
    
    // Helper function to get first and last added song dates
    private func dateRange() -> (first: Date?, last: Date?) {
        let dates = playlist.songs.compactMap { $0.dateAdded }
        return (dates.min(), dates.max())
    }
    
    var body: some View {
        List {
            // Playlist header section
            Section(header: DetailHeaderView(
                title: playlist.name,
                subtitle: "",
                plays: playlist.totalPlayCount,
                songCount: playlist.songs.count,
                artwork: playlist.artwork,
                isAlbum: false,
                metadata: []
            )) {
                // Empty section content for spacing
            }
            
            // Playlist Statistics section - moved above the content sections
            Section(header: Text("Playlist Statistics")
                .padding(.leading, -15)) {
                metadataRow(icon: "square.stack", title: "Albums", value: "\(uniqueAlbums())")
                    .listRowSeparator(.hidden)
                metadataRow(icon: "music.note.list", title: "Top Genres", value: topGenres().joined(separator: ", "))
                    .listRowSeparator(.hidden)
                metadataRow(icon: "clock", title: "Total Time", value: totalDuration())
                    .listRowSeparator(.hidden)
                metadataRow(icon: "plus.circle", title: "First Added", value: formatDate(dateRange().first))
                    .listRowSeparator(.hidden)
                
                // Most recent addition
                if let lastAdded = dateRange().last {
                    metadataRow(icon: "calendar", title: "Last Added", value: formatDate(lastAdded))
                        .listRowSeparator(.hidden)
                }
                
                // Average plays per song
                let avgPlays = playlist.totalPlayCount / max(1, playlist.songs.count)
                metadataRow(icon: "repeat", title: "Avg. Plays", value: "\(avgPlays) per song")
                    .listRowSeparator(.hidden)
            }
            
            // Artists section - top 3 artists in the playlist, sorted by PLAY COUNT
            Section(header: Text("Top Artists").padding(.leading, -15)) {
                ForEach(topArtists(), id: \.name) { artist, songCount, playCount in
                    if let artistData = musicLibrary.artists.first(where: { $0.name == artist }) {
                        NavigationLink(destination: ArtistDetailView(artist: artistData)) {
                            HStack {
                                ArtistRow(artist: artistData)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("\(playCount) plays")
                                        .font(AppStyles.playCountStyle)
                                        .foregroundColor(AppStyles.accentColor)
                                    
                                    Text("\(songCount) songs")
                                        .font(AppStyles.captionStyle)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(AppStyles.secondaryColor)
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "music.mic")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(artist)
                                    .font(AppStyles.bodyStyle)
                                
                                Text("\(songCount) songs in playlist")
                                    .font(AppStyles.captionStyle)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(playCount) plays")
                                .font(AppStyles.playCountStyle)
                                .foregroundColor(AppStyles.accentColor)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            
            // Songs section
            Section(header: Text("Songs").padding(.leading, -15)) {
                ForEach(playlist.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }, id: \.persistentID) { song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        SongRow(song: song)
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
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
