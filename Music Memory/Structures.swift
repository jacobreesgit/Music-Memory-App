//
//  Structures.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI
import MediaPlayer

struct AlbumData: Identifiable {
    let id: String
    let title: String
    let artist: String
    let artwork: MPMediaItemArtwork?
    var songs: [MPMediaItem]
    var totalPlayCount: Int
}

struct ArtistData: Identifiable {
    var id: String { name }
    let name: String
    var songs: [MPMediaItem]
    var totalPlayCount: Int
    
    // Get artwork from the most-played song with artwork
    var artwork: MPMediaItemArtwork? {
        return songs.sorted(by: { ($0.playCount ?? 0) > ($1.playCount ?? 0) })
                    .first(where: { $0.artwork != nil })?.artwork
    }
}
