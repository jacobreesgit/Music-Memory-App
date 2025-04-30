//
//  PlaylistData.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import MediaPlayer

/// Model for playlist data with play count tracking
struct PlaylistData: Identifiable, Equatable {
    // MARK: - Properties
    var id: String { name }
    let name: String
    var songs: [MPMediaItem]
    var totalPlayCount: Int
    let playlistID: MPMediaEntityPersistentID
    
    // MARK: - Computed Properties
    
    /// Get artwork from the first song with artwork
    var artwork: MPMediaItemArtwork? {
        return songs.first(where: { $0.artwork != nil })?.artwork
    }
    
    /// Average play count per song
    var averagePlayCount: Int {
        songs.isEmpty ? 0 : totalPlayCount / songs.count
    }
    
    /// Unique artists in this playlist
    var uniqueArtists: Set<String> {
        Set(songs.compactMap { $0.artist })
    }
    
    /// Count of unique artists
    var artistCount: Int {
        uniqueArtists.count
    }
    
    /// Unique albums in this playlist
    var uniqueAlbums: Set<String> {
        Set(songs.compactMap { $0.albumTitle })
    }
    
    /// Count of unique albums
    var albumCount: Int {
        uniqueAlbums.count
    }
    
    /// Helper function to get most common genres
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
    
    /// Helper function to get top artists sorted by play count
    func topArtists(limit: Int = 3) -> [(name: String, songCount: Int, playCount: Int)] {
        var artistSongCounts: [String: Int] = [:]
        var artistPlayCounts: [String: Int] = [:]
        
        for song in songs {
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
    
    // MARK: - Equatable
    
    /// Implement Equatable
    static func == (lhs: PlaylistData, rhs: PlaylistData) -> Bool {
        return lhs.playlistID == rhs.playlistID
    }
}
