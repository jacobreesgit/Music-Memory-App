// MusicHighlightsIntent.swift
// MusicMemoryWidgets

import AppIntents
import WidgetKit
import SwiftUI

// Configuration options for the Music Highlights widget
struct MusicHighlightsIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Music Highlights Configuration"
    static var description = IntentDescription("Configure what music stats to display")
    
    // Content type selection
    @Parameter(title: "Content Type", default: .songs)
    var contentType: MusicContentType
    
    // Custom title option
    @Parameter(title: "Custom Title",
              description: "Leave empty to use default title",
              default: "")
    var customTitle: String
    
    // Show/hide play counts option
    @Parameter(title: "Show Play Counts", default: true)
    var showPlayCounts: Bool
}

// Enum for content type selection - make this public so it can be accessed from main app
public enum MusicContentType: String, AppEnum {
    case songs
    case artists
    case albums
    case playlists
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Content Type")
    
    static var caseDisplayRepresentations: [MusicContentType: DisplayRepresentation] = [
        .songs: .init(title: "Songs"),
        .artists: .init(title: "Artists"),
        .albums: .init(title: "Albums"),
        .playlists: .init(title: "Playlists")
    ]
    
    // Helper to get display title - make public
    public var displayTitle: String {
        switch self {
        case .songs: return "Top Songs"
        case .artists: return "Top Artists"
        case .albums: return "Top Albums"
        case .playlists: return "Top Playlists"
        }
    }
    
    // Helper to get icon name - make public
    public var iconName: String {
        switch self {
        case .songs: return "music.note"
        case .artists: return "music.mic"
        case .albums: return "square.stack"
        case .playlists: return "music.note.list"
        }
    }
}
