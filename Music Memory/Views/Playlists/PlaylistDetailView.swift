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
            
            // Playlist Statistics section
            Section(header: Text("Playlist Statistics")
                .padding(.leading, -15)) {
                MetadataRow(icon: "square.stack", title: "Albums", value: "\(playlist.albumCount)")
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "music.note.list", title: "Top Genres", value: playlist.topGenres().joined(separator: ", "))
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "clock", title: "Total Time", value: totalDuration())
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "plus.circle", title: "First Added", value: formatDate(dateRange().first))
                    .listRowSeparator(.hidden)
                
                // Most recent addition
                if let lastAdded = dateRange().last {
                    MetadataRow(icon: "calendar", title: "Last Added", value: formatDate(lastAdded))
                        .listRowSeparator(.hidden)
                }
                
                // Average plays per song
                MetadataRow(icon: "repeat", title: "Avg. Plays", value: "\(playlist.averagePlayCount) per song")
                    .listRowSeparator(.hidden)
            }
            
            // Artists section - top 3 artists in the playlist, sorted by PLAY COUNT
            Section(header: Text("Top Artists").padding(.leading, -15)) {
                ForEach(playlist.topArtists(), id: \.name) { artist, songCount, playCount in
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
}
