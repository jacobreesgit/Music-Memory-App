//
//  AlbumData.swift
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
}

struct TopItem {
    let title: String
    let subtitle: String
    let plays: Int
    let artwork: MPMediaItemArtwork?
}