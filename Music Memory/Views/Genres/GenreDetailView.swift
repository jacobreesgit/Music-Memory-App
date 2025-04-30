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
    let rank: Int?
    
    // Initialize with an optional rank parameter
    init(genre: GenreData, rank: Int? = nil) {
        self.genre = genre
        self.rank = rank
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
            // Genre header section with optional rank
            Section(header: VStack(alignment: .center, spacing: 4) {
                if let rank = rank {
                    Text("Rank #\(rank)")
                        .font(.headline)
                        .foregroundColor(AppStyles.accentColor)
                        .padding(.bottom, 4)
                }
                
                DetailHeaderView(
                    title: genre.name,
                    subtitle: "",
                    plays: genre.totalPlayCount,
                    songCount: genre.songs.count,
                    artwork: genre.artwork,
                    isAlbum: false,
                    metadata: []
                )
            }) {
                // Empty section content for spacing
            }
            
            // Genre Statistics section
            Section(header: Text("Genre Statistics")
                .padding(.leading, -15)) {
                MetadataRow(icon: "music.mic", title: "Artists", value: "\(genre.artistCount)")
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "square.stack", title: "Albums", value: "\(genre.albumCount)")
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "clock", title: "Total Time", value: totalDuration())
                    .listRowSeparator(.hidden)
                
                // Average play count per song
                MetadataRow(icon: "repeat", title: "Avg. Plays", value: "\(genre.averagePlayCount) per song")
                    .listRowSeparator(.hidden)
            }
            
            // Songs section with ranking
            Section(header: Text("Songs").padding(.leading, -15)) {
                ForEach(Array(genre.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }.enumerated()), id: \.element.persistentID) { index, song in
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
        .navigationTitle(genre.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
