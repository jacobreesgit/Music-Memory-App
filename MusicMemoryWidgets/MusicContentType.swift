// MusicMemoryWidgets/MusicContentType.swift
import AppIntents
import Foundation
import SwiftUI

// Enum for content type selection
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
    
    // Helper to get display title
    public var displayTitle: String {
        switch self {
        case .songs: return "Top Songs"
        case .artists: return "Top Artists"
        case .albums: return "Top Albums"
        case .playlists: return "Top Playlists"
        }
    }
    
    // Helper to get icon name
    public var iconName: String {
        switch self {
        case .songs: return "music.note"
        case .artists: return "music.mic"
        case .albums: return "square.stack"
        case .playlists: return "music.note.list"
        }
    }
}
