// Music Memory/Components/Lists/MediaListDisplayable.swift
import SwiftUI
import MediaPlayer

/// Protocol defining requirements for displaying an item in a list view
protocol MediaListDisplayable: Identifiable {
    // Core display properties
    var listTitle: String { get }
    var listSubtitle: String { get }
    var listPlayCount: Int { get }
    var listArtwork: MPMediaItemArtwork? { get }
    
    // For placeholder icon when no artwork is available
    var listIconName: String { get }
    
    // Optional customization properties with default implementations
    var useCircularArtwork: Bool { get }
    
    // For navigating to detail views
    associatedtype DetailView: View
    func createDetailView(rank: Int?) -> DetailView
}

// Default implementation
extension MediaListDisplayable {
    var useCircularArtwork: Bool { return false }
}
