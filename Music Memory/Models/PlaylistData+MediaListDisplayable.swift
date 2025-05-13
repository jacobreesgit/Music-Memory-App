// Music Memory/Models/PlaylistData+MediaListDisplayable.swift
import SwiftUI
import MediaPlayer

extension PlaylistData: MediaListDisplayable {
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
        return PlaylistDetailView(playlist: self, rank: rank)
    }
}
