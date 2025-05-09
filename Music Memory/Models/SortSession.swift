//
//  SortSession.swift
//  Music Memory
//
//  Created by Jacob Rees on 07/05/2025.
//

import SwiftUI
import MediaPlayer

/// Model for tracking and storing sorting sessions for any type of music content
struct SortSession: Identifiable, Codable {
    // MARK: - Properties
    var id = UUID()
    let title: String
    let source: SortSource
    let sourceID: String
    let sourceName: String
    let date: Date
    
    // The type of content being sorted
    let contentType: ContentType
    
    // Item IDs stored as strings (could be songs, albums, artists, etc.)
    var itemIDs: [String]
    var sortedIDs: [String] // The result of the sorting
    var isComplete: Bool
    var artworkData: Data? // Store artwork data
    
    // New properties to track battle progress
    var currentBattleIndex: Int = 0 // Track the current battle number
    var battleHistory: [BattleRecord] = [] // Store history of battles
    
    // Source type for the sort session
    enum SortSource: String, Codable {
        case album
        case artist
        case genre
        case playlist
    }
    
    // Type of content being sorted
    enum ContentType: String, Codable {
        case songs
        case albums
        case artists
        case genres
        case playlists
    }
    
    // Structure to record battle information
    struct BattleRecord: Codable, Equatable {
        let leftItemID: String
        let rightItemID: String
        let battleIndex: Int
        
        static func == (lhs: BattleRecord, rhs: BattleRecord) -> Bool {
            return lhs.leftItemID == rhs.rightItemID &&
                   lhs.rightItemID == rhs.rightItemID &&
                   lhs.battleIndex == rhs.battleIndex
        }
    }
    
    // MARK: - Computed Properties
    
    /// The number of decisions made in the sorting process
    var decisionCount: Int {
        sortedIDs.count
    }
    
    /// The number of total items being sorted
    var totalItems: Int {
        itemIDs.count
    }
    
    /// The progress of the sorting (0.0 - 1.0)
    var progress: Double {
        if totalItems <= 1 {
            return 1.0
        }
        return Double(decisionCount) / Double(totalItems)
    }
    
    // MARK: - Initialization
    
    /// Initialize with a list of songs
    init(title: String, songs: [MPMediaItem], source: SortSource, sourceID: String, sourceName: String, artwork: MPMediaItemArtwork? = nil) {
        self.title = title
        self.source = source
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.date = Date()
        self.contentType = .songs
        self.itemIDs = songs.map { $0.persistentID.description }
        self.sortedIDs = []
        self.isComplete = false
        self.currentBattleIndex = 0
        self.battleHistory = []
        
        // Convert artwork to data if available
        if let artwork = artwork, let image = artwork.image(at: CGSize(width: 100, height: 100)) {
            self.artworkData = image.pngData()
        }
    }
    
    /// Initialize with a list of albums
    init(title: String, albums: [AlbumData], source: SortSource, sourceID: String, sourceName: String, artwork: MPMediaItemArtwork? = nil) {
        self.title = title
        self.source = source
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.date = Date()
        self.contentType = .albums
        self.itemIDs = albums.map { $0.id }
        self.sortedIDs = []
        self.isComplete = false
        self.currentBattleIndex = 0
        self.battleHistory = []
        
        // Convert artwork to data if available
        if let artwork = artwork, let image = artwork.image(at: CGSize(width: 100, height: 100)) {
            self.artworkData = image.pngData()
        }
    }
    
    /// Initialize with a list of artists
    init(title: String, artists: [ArtistData], source: SortSource, sourceID: String, sourceName: String, artwork: MPMediaItemArtwork? = nil) {
        self.title = title
        self.source = source
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.date = Date()
        self.contentType = .artists
        self.itemIDs = artists.map { $0.id }
        self.sortedIDs = []
        self.isComplete = false
        self.currentBattleIndex = 0
        self.battleHistory = []
        
        // Convert artwork to data if available
        if let artwork = artwork, let image = artwork.image(at: CGSize(width: 100, height: 100)) {
            self.artworkData = image.pngData()
        }
    }
    
    /// Initialize with a list of genres
    init(title: String, genres: [GenreData], source: SortSource, sourceID: String, sourceName: String, artwork: MPMediaItemArtwork? = nil) {
        self.title = title
        self.source = source
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.date = Date()
        self.contentType = .genres
        self.itemIDs = genres.map { $0.id }
        self.sortedIDs = []
        self.isComplete = false
        self.currentBattleIndex = 0
        self.battleHistory = []
        
        // Convert artwork to data if available
        if let artwork = artwork, let image = artwork.image(at: CGSize(width: 100, height: 100)) {
            self.artworkData = image.pngData()
        }
    }
    
    /// Initialize with a list of playlists
    init(title: String, playlists: [PlaylistData], source: SortSource, sourceID: String, sourceName: String, artwork: MPMediaItemArtwork? = nil) {
        self.title = title
        self.source = source
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.date = Date()
        self.contentType = .playlists
        self.itemIDs = playlists.map { $0.id }
        self.sortedIDs = []
        self.isComplete = false
        self.currentBattleIndex = 0
        self.battleHistory = []
        
        // Convert artwork to data if available
        if let artwork = artwork, let image = artwork.image(at: CGSize(width: 100, height: 100)) {
            self.artworkData = image.pngData()
        }
    }
    
    // Backwards compatibility initializer
    init(legacySession: SortSession) {
        self.id = legacySession.id
        self.title = legacySession.title
        self.source = legacySession.source
        self.sourceID = legacySession.sourceID
        self.sourceName = legacySession.sourceName
        self.date = legacySession.date
        self.contentType = .songs // Assume legacy sessions are for songs
        self.itemIDs = legacySession.itemIDs
        self.sortedIDs = legacySession.sortedIDs
        self.isComplete = legacySession.isComplete
        self.artworkData = legacySession.artworkData
        self.currentBattleIndex = legacySession.currentBattleIndex
        self.battleHistory = legacySession.battleHistory.map {
            BattleRecord(
                leftItemID: $0.leftItemID,
                rightItemID: $0.rightItemID,
                battleIndex: $0.battleIndex
            )
        }
    }
    
    // For backward compatibility
    var songIDs: [String] {
        get { return contentType == .songs ? itemIDs : [] }
        set { if contentType == .songs { itemIDs = newValue } }
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
                // Apply migration before publishing
                sessions = migrateSessionsIfNeeded(decoded)
            }
        }
    }
    
    /// Migrate older sessions to include the new properties
    private func migrateSessionsIfNeeded(_ sessions: [SortSession]) -> [SortSession] {
        var migratedSessions: [SortSession] = []
        
        for var session in sessions {
            // Check if this is an older session with currentBattleIndex not set properly
            if session.currentBattleIndex == 0 && session.sortedIDs.count > 0 {
                // Set it to match the number of completed sorts
                session.currentBattleIndex = session.sortedIDs.count
            }
            
            migratedSessions.append(session)
        }
        
        return migratedSessions
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
    /// Simple implementation of merge sort for determining item order
    static func mergeSort<T>(_ items: [T],
                       comparator: @escaping (T, T) async -> Bool) async -> [T] {
        
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
    private static func merge<T>(_ left: [T], _ right: [T],
                           comparator: @escaping (T, T) async -> Bool) async -> [T] {
        
        var result: [T] = []
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
