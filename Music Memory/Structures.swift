//
//  Structures.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI
import MediaPlayer

struct AlbumData: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let artwork: MPMediaItemArtwork?
    var songs: [MPMediaItem]
    var totalPlayCount: Int
    
    // Implement Equatable
    static func == (lhs: AlbumData, rhs: AlbumData) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ArtistData: Identifiable, Equatable {
    var id: String { name }
    let name: String
    var songs: [MPMediaItem]
    var totalPlayCount: Int
    
    // Get artwork from the most-played song with artwork
    var artwork: MPMediaItemArtwork? {
        return songs.sorted(by: { ($0.playCount ?? 0) > ($1.playCount ?? 0) })
                    .first(where: { $0.artwork != nil })?.artwork
    }
    
    // Implement Equatable
    static func == (lhs: ArtistData, rhs: ArtistData) -> Bool {
        return lhs.name == rhs.name
    }
}
