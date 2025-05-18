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
    let artworkFilename: String?  // Changed from artworkData to artworkFilename
    
    // Maintain backward compatibility while changing implementation
    init(id: String, title: String, subtitle: String, plays: Int, artworkData: Data?) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.plays = plays
        
        // If artwork data is provided, save it to filesystem and store the filename
        if let data = artworkData {
            self.artworkFilename = MusicHighlightsDataStore.shared.saveArtwork(data: data, forID: id)
        } else {
            self.artworkFilename = nil
        }
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
    
    // MARK: - Artwork File Management
    
    // Save artwork to filesystem and return the filename
    func saveArtwork(data: Data, forID id: String) -> String {
        let filename = "artwork_\(id).jpg"
        
        // Get shared container URL for app group
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.media.music-memory.jacobrees.com"
        ) {
            let artworkDir = containerURL.appendingPathComponent("artwork", isDirectory: true)
            let fileURL = artworkDir.appendingPathComponent(filename)
            
            // Create directory if needed
            do {
                try FileManager.default.createDirectory(at: artworkDir, withIntermediateDirectories: true, attributes: nil)
                
                // Resize image before saving to reduce storage requirements
                if let image = UIImage(data: data) {
                    let resizedImage = resizeImage(image, targetSize: CGSize(width: 150, height: 150))
                    if let jpegData = resizedImage.jpegData(compressionQuality: 0.7) {
                        try jpegData.write(to: fileURL)
                        return filename
                    }
                }
                
                // Fallback if resizing fails
                try data.write(to: fileURL)
                return filename
            } catch {
                print("Error saving artwork: \(error.localizedDescription)")
            }
        }
        
        return ""
    }
    
    // Load artwork from filesystem
    func loadArtwork(filename: String?) -> UIImage? {
        guard let filename = filename, !filename.isEmpty else {
            return nil
        }
        
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.media.music-memory.jacobrees.com"
        ) {
            let fileURL = containerURL.appendingPathComponent("artwork").appendingPathComponent(filename)
            if let data = try? Data(contentsOf: fileURL) {
                return UIImage(data: data)
            }
        }
        
        return nil
    }
    
    // Helper function to resize images
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // Create a new renderer to draw the resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
}
