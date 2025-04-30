//
//  ArtistData.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

/// Model for artist data with play count tracking
struct ArtistData: Identifiable, Equatable {
    // MARK: - Properties
    var id: String { name }
    let name: String
    var songs: [MPMediaItem]
    var totalPlayCount: Int
    
    // MARK: - Computed Properties
    
    /// Get artwork from the most-played song with artwork
    var artwork: MPMediaItemArtwork? {
        return songs.sorted(by: { ($0.playCount ?? 0) > ($1.playCount ?? 0) })
                    .first(where: { $0.artwork != nil })?.artwork
    }
    
    /// Average play count per song
    var averagePlayCount: Int {
        songs.isEmpty ? 0 : totalPlayCount / songs.count
    }
    
    /// Unique album titles for this artist
    var uniqueAlbums: Set<String> {
        Set(songs.compactMap { $0.albumTitle })
    }
    
    /// Count of unique albums
    var albumCount: Int {
        uniqueAlbums.count
    }
    
    /// Most common genres for this artist
    func topGenres(limit: Int = 3) -> [String] {
        var genreCounts: [String: Int] = [:]
        
        for song in songs {
            if let genre = song.genre, !genre.isEmpty {
                genreCounts[genre, default: 0] += 1
            }
        }
        
        return genreCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
    
    // MARK: - Equatable
    
    /// Implement Equatable
    static func == (lhs: ArtistData, rhs: ArtistData) -> Bool {
        return lhs.name == rhs.name
    }
}
