// Music Memory/Models/ArtistData+MediaListDisplayable.swift
import SwiftUI
import MediaPlayer

extension ArtistData: MediaListDisplayable {
    var listTitle: String {
        return name
    }
    
    var listSubtitle: String {
        return "\(songs.count) songs"
    }
    
    var listPlayCount: Int {
        return totalPlayCount
    }
    
    var listArtwork: MPMediaItemArtwork? {
        return artwork
    }
    
    var listIconName: String {
        return "music.mic"
    }
    
    var useCircularArtwork: Bool {
        return true
    }
    
    func createDetailView(rank: Int?) -> some View {
        return ArtistDetailView(artist: self, rank: rank)
    }
}
