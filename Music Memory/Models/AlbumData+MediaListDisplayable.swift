// Music Memory/Models/AlbumData+MediaListDisplayable.swift
import SwiftUI
import MediaPlayer

extension AlbumData: MediaListDisplayable {
    var listTitle: String {
        return title
    }
    
    var listSubtitle: String {
        return artist
    }
    
    var listPlayCount: Int {
        return totalPlayCount
    }
    
    var listArtwork: MPMediaItemArtwork? {
        return artwork
    }
    
    var listIconName: String {
        return "square.stack"
    }
    
    func createDetailView(rank: Int?) -> some View {
        return AlbumDetailView(album: self, rank: rank)
    }
}
