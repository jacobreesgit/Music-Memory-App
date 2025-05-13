// Music Memory/Models/MPMediaItem+MediaListDisplayable.swift
import SwiftUI
import MediaPlayer

// Remove @retroactive since MediaListDisplayable is defined in our module
extension MPMediaItem: MediaListDisplayable {
    public var id: MPMediaEntityPersistentID { persistentID }
    
    public var listTitle: String {
        return title ?? "Unknown"
    }
    
    public var listSubtitle: String {
        return artist ?? "Unknown"
    }
    
    public var listPlayCount: Int {
        return playCount
    }
    
    public var listArtwork: MPMediaItemArtwork? {
        return artwork
    }
    
    public var listIconName: String {
        return "music.note"
    }
    
    public func createDetailView(rank: Int?) -> some View {
        return SongDetailView(song: self, rank: rank)
    }
}
