//
//  SortSession.swift
//  Music Memory
//
//  Created by Jacob Rees on 07/05/2025.
//

import SwiftUI
import MediaPlayer

/// Model for tracking and storing song sorting sessions
struct SortSession: Identifiable, Codable {
    // MARK: - Properties
    var id = UUID()
    let title: String
    let source: SortSource
    let sourceID: String
    let sourceName: String
    let date: Date
    var songIDs: [String] // Persistent IDs stored as strings
    var sortedIDs: [String] // The result of the sorting
    var isComplete: Bool
    var artworkData: Data? // Store artwork data
    
    // Source type for the sort session
    enum SortSource: String, Codable {
        case album
        case artist
        case genre
        case playlist
    }
    
    // MARK: - Computed Properties
    
    /// The number of decisions made in the sorting process
    var decisionCount: Int {
        sortedIDs.count
    }
    
    /// The number of total items being sorted
    var totalItems: Int {
        songIDs.count
    }
    
    /// The progress of the sorting (0.0 - 1.0)
    var progress: Double {
        if totalItems <= 1 {
            return 1.0
        }
        return Double(decisionCount) / Double(totalItems)
    }
    
    // MARK: - Initialization
    
    /// Initialize with a list of songs and source information
    init(title: String, songs: [MPMediaItem], source: SortSource, sourceID: String, sourceName: String, artwork: MPMediaItemArtwork? = nil) {
        self.title = title
        self.source = source
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.date = Date()
        self.songIDs = songs.map { $0.persistentID.description }
        self.sortedIDs = []
        self.isComplete = false
        
        // Convert artwork to data if available
        if let artwork = artwork, let image = artwork.image(at: CGSize(width: 100, height: 100)) {
            self.artworkData = image.pngData()
        }
    }
}

// MARK: - SortSessionStore

/// Manages the storage and retrieval of sort sessions
class SortSessionStore: ObservableObject {
    @Published var sessions: [SortSession] = []
    
    private let saveKey = "saved_sort_sessions"
    
    init() {
        loadSessions()
    }
    
    /// Load saved sort sessions from UserDefaults
    func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([SortSession].self, from: data) {
                sessions = decoded
            }
        }
    }
    
    /// Save sessions to UserDefaults
    func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    /// Add a new sort session
    func addSession(_ session: SortSession) {
        sessions.append(session)
        saveSessions()
    }
    
    /// Update an existing sort session
    func updateSession(_ session: SortSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            saveSessions()
        }
    }
    
    /// Delete a sort session
    func deleteSession(at indexSet: IndexSet) {
        sessions.remove(atOffsets: indexSet)
        saveSessions()
    }
    
    /// Clear all sessions
    func clearAllSessions() {
        sessions.removeAll()
        saveSessions()
    }
}

// MARK: - SortAlgorithm

/// Contains sorting algorithm implementations
enum SortAlgorithm {
    /// Simple implementation of merge sort for determining song order
    static func mergeSort(_ items: [MPMediaItem],
                       comparator: @escaping (MPMediaItem, MPMediaItem) async -> Bool) async -> [MPMediaItem] {
        
        guard items.count > 1 else { return items }
        
        // Simple case: just two items
        if items.count == 2 {
            if await comparator(items[0], items[1]) {
                return items
            } else {
                return [items[1], items[0]]
            }
        }
        
        // Recursive case
        let middle = items.count / 2
        let left = Array(items[0..<middle])
        let right = Array(items[middle..<items.count])
        
        let sortedLeft = await mergeSort(left, comparator: comparator)
        let sortedRight = await mergeSort(right, comparator: comparator)
        
        return await merge(sortedLeft, sortedRight, comparator: comparator)
    }
    
    /// Merge two sorted arrays
    private static func merge(_ left: [MPMediaItem], _ right: [MPMediaItem],
                           comparator: @escaping (MPMediaItem, MPMediaItem) async -> Bool) async -> [MPMediaItem] {
        
        var result: [MPMediaItem] = []
        var leftIndex = 0
        var rightIndex = 0
        
        while leftIndex < left.count && rightIndex < right.count {
            if await comparator(left[leftIndex], right[rightIndex]) {
                result.append(left[leftIndex])
                leftIndex += 1
            } else {
                result.append(right[rightIndex])
                rightIndex += 1
            }
        }
        
        // Add remaining elements
        if leftIndex < left.count {
            result.append(contentsOf: left[leftIndex..<left.count])
        }
        
        if rightIndex < right.count {
            result.append(contentsOf: right[rightIndex..<right.count])
        }
        
        return result
    }
}
