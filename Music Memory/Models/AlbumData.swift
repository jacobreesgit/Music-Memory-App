//
//  AlbumData.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

/// Model for album data with play count tracking
struct AlbumData: Identifiable, Equatable {
    // MARK: - Properties
    let id: String
    let title: String
    let artist: String
    let artwork: MPMediaItemArtwork?
    var songs: [MPMediaItem]
    var totalPlayCount: Int
    
    // MARK: - Computed Properties
    
    /// Average play count per song
    var averagePlayCount: Int {
        songs.isEmpty ? 0 : totalPlayCount / songs.count
    }
    
    /// Most common genre in the album
    var primaryGenre: String {
        var genreCounts: [String: Int] = [:]
        
        for song in songs {
            if let genre = song.genre {
                genreCounts[genre, default: 0] += 1
            }
        }
        
        return genreCounts.max(by: { $0.value < $1.value })?.key ?? "Unknown"
    }
    
    // MARK: - Equatable
    
    /// Implement Equatable
    static func == (lhs: AlbumData, rhs: AlbumData) -> Bool {
        return lhs.id == rhs.id
    }
}
