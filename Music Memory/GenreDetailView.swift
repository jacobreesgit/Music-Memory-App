//
//  GenreDetailView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//


//
//  GenreDetailView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//

import SwiftUI
import MediaPlayer

struct GenreDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let genre: GenreData
    
    // Helper function to get unique artists count
    private func artistCount() -> Int {
        return Set(genre.songs.compactMap { $0.artist }).count
    }
    
    // Helper function to get unique albums count
    private func albumCount() -> Int {
        return Set(genre.songs.compactMap { $0.albumTitle }).count
    }
    
    // Helper function to format total duration
    private func totalDuration() -> String {
        let totalSeconds = genre.songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return String(format: "%dh %dm", hours, minutes)
    }
    
    var body: some View {
        List {
            // Genre header section
            Section(header: DetailHeaderView(
                title: genre.name,
                subtitle: "",
                plays: genre.totalPlayCount,
                songCount: genre.songs.count,
                artwork: genre.artwork,
                isAlbum: false,
                metadata: []
            )) {
                // Empty section content for spacing
            }
            
            // Songs section
            Section(header: Text("Songs").padding(.leading, -15)) {
                ForEach(genre.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }, id: \.persistentID) { song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        SongRow(song: song)
                    }
                    .listRowSeparator(.hidden)
                }
            }
            
            // Genre Statistics section
            Section(header: Text("Genre Statistics")
                .padding(.leading, -15)) {
                metadataRow(icon: "music.mic", title: "Artists", value: "\(artistCount())")
                    .listRowSeparator(.hidden)
                metadataRow(icon: "square.stack", title: "Albums", value: "\(albumCount())")
                    .listRowSeparator(.hidden)
                metadataRow(icon: "clock", title: "Total Time", value: totalDuration())
                    .listRowSeparator(.hidden)
                
                // Average play count per song
                let avgPlays = genre.totalPlayCount / max(1, genre.songs.count)
                metadataRow(icon: "repeat", title: "Avg. Plays", value: "\(avgPlays) per song")
                    .listRowSeparator(.hidden)
            }
        }
        .navigationTitle(genre.name)
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