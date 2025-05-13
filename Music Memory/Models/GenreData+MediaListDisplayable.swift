// Music Memory/Models/GenreData+MediaListDisplayable.swift
import SwiftUI
import MediaPlayer

extension GenreData: MediaListDisplayable {
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
        return "music.note.list"
    }
    
    func createDetailView(rank: Int?) -> some View {
        return GenreDetailView(genre: self, rank: rank)
    }
}
