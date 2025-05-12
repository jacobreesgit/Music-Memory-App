//  MediaDetailProtocols.swift
//  Music Memory

import SwiftUI
import MediaPlayer

/// Protocol defining requirements for displaying an item in a detail view
protocol MediaDetailDisplayable {
    // Core display properties
    var displayTitle: String { get }
    var displaySubtitle: String { get }
    var totalPlayCount: Int { get }
    var itemCount: Int { get }
    var artwork: MPMediaItemArtwork? { get }
    var isAlbumType: Bool { get }
    
    // Optional rank for display in header
    var displayRank: Int? { get }
    
    // Metadata for statistics section
    func getMetadataItems() -> [MetadataItem]
    
    // Consistent date formatting
    func formatDate(_ date: Date?) -> String
}

// Default implementation
extension MediaDetailDisplayable {
    // Default date formatting for consistency
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Default for displays that don't have a natural rank
    var displayRank: Int? { return nil }
    
    // Default implementation assumes this isn't an album type
    var isAlbumType: Bool { return false }
}
