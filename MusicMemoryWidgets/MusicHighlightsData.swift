// MusicHighlightsData.swift
// Shared between app and widget extension

import Foundation
import WidgetKit
import SwiftUI
import MusicMemoryWidgetsExtension

// Struct to hold shared music item data for widgets
struct MusicHighlightsItem: Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let plays: Int
    let artworkData: Data?
    
    // Create a more lightweight version for widget use
    init(id: String, title: String, subtitle: String, plays: Int, artworkData: Data?) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.plays = plays
        self.artworkData = artworkData
    }
}

// Model class for widget data access
class MusicHighlightsDataStore {
    static let shared = MusicHighlightsDataStore()
    
    // UserDefaults suite for app group
    private let defaults = UserDefaults(suiteName: "group.media.music-memory.jacobrees.com")
    
    // Keys for storing different data types
    private enum StoreKey: String {
        case topSongs = "topSongs"
        case topArtists = "topArtists"
        case topAlbums = "topAlbums"
        case topPlaylists = "topPlaylists"
        case lastUpdated = "lastUpdated"
    }
    
    // Save top items data to shared UserDefaults
    func saveTopItems(_ items: [MusicHighlightsItem], forType type: MusicContentType) {
        let key = getKeyForType(type)
        if let encoded = try? JSONEncoder().encode(items) {
            defaults?.set(encoded, forKey: key.rawValue)
            defaults?.set(Date(), forKey: StoreKey.lastUpdated.rawValue)
        }
    }
    
    // Get top items data from shared UserDefaults
    func getTopItems(forType type: MusicContentType) -> [MusicHighlightsItem] {
        let key = getKeyForType(type)
        guard let data = defaults?.data(forKey: key.rawValue),
              let decoded = try? JSONDecoder().decode([MusicHighlightsItem].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // Get when the data was last updated
    func getLastUpdated() -> Date? {
        return defaults?.object(forKey: StoreKey.lastUpdated.rawValue) as? Date
    }
    
    // Helper to get key based on content type
    private func getKeyForType(_ type: MusicContentType) -> StoreKey {
        switch type {
        case .songs: return .topSongs
        case .artists: return .topArtists
        case .albums: return .topAlbums
        case .playlists: return .topPlaylists
        }
    }
}
