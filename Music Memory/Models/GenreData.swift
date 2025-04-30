//
//  GenreData.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

/// Model for genre data with play count tracking
struct GenreData: Identifiable, Equatable {
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
    
    /// Unique artists in this genre
    var uniqueArtists: Set<String> {
        Set(songs.compactMap { $0.artist })
    }
    
    /// Count of unique artists
    var artistCount: Int {
        uniqueArtists.count
    }
    
    /// Unique albums in this genre
    var uniqueAlbums: Set<String> {
        Set(songs.compactMap { $0.albumTitle })
    }
    
    /// Count of unique albums
    var albumCount: Int {
        uniqueAlbums.count
    }
    
    // MARK: - Equatable
    
    /// Implement Equatable
    static func == (lhs: GenreData, rhs: GenreData) -> Bool {
        return lhs.name == rhs.name
    }
}
