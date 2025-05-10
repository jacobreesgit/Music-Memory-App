//
//  SongVersionModel.swift
//  Music Memory
//
//  Created by Jacob Rees on 10/05/2025.
//

import Foundation
import MediaPlayer
import MusicKit
import SwiftUI

class SongVersionModel: ObservableObject {
    @Published var replacementMap: [MPMediaItem: Song] = [:]
    @Published var isProcessing = false
    @Published var processedItems = 0
    @Published var totalItems = 0
    
    func addToReplacementMap(_ librarySong: MPMediaItem, replacement: Song) {
        replacementMap[librarySong] = replacement
    }
    
    func removeFromReplacementMap(_ librarySong: MPMediaItem) {
        replacementMap.removeValue(forKey: librarySong)
    }
    
    func clearReplacementMap() {
        replacementMap.removeAll()
    }
    
    func processSongs(_ songs: [MPMediaItem]) async {
        await MainActor.run {
            self.isProcessing = true
            self.processedItems = 0
            self.totalItems = songs.count
        }
        
        for (index, song) in songs.enumerated() {
            // Find versions for this song
            let versions = await AppleMusicManager.shared.findVersionsForSong(song)
            
            // If any versions found, use the first one as replacement
            if let firstVersion = versions.first {
                await MainActor.run {
                    self.replacementMap[song] = firstVersion
                    self.processedItems = index + 1
                }
            } else {
                await MainActor.run {
                    self.processedItems = index + 1
                }
            }
        }
        
        await MainActor.run {
            self.isProcessing = false
        }
    }
    
    func getVersionDifferences(libraryItem: MPMediaItem, catalogItem: Song) -> [VersionDifference] {
        var differences: [VersionDifference] = []
        
        // Check for remastered/deluxe versions
        if catalogItem.title.lowercased().contains("remaster") ||
           (catalogItem.albumTitle?.lowercased().contains("remaster") ?? false) {
            differences.append(.remastered)
        }
        
        if catalogItem.title.lowercased().contains("deluxe") ||
           (catalogItem.albumTitle?.lowercased().contains("deluxe") ?? false) {
            differences.append(.deluxeEdition)
        }
        
        // Check for high resolution audio
        if catalogItem.audioVariants?.contains(.lossless) == true {
            differences.append(.lossless)
        }
        
        if catalogItem.audioVariants?.contains(.dolbyAtmos) == true {
            differences.append(.dolbyAtmos)
        }
        
        // Check release date differences
        if let catalogReleaseDate = catalogItem.releaseDate,
           let libraryReleaseDate = libraryItem.releaseDate,
           catalogReleaseDate > libraryReleaseDate {
            differences.append(.newer)
        }
        
        // Check explicit differences
        if catalogItem.contentRating == .explicit && !libraryItem.isExplicitItem {
            differences.append(.explicitVersion)
        } else if catalogItem.contentRating != .explicit && libraryItem.isExplicitItem {
            differences.append(.cleanVersion)
        }
        
        // If no differences found, but it's still a match, mark as alternative version
        if differences.isEmpty {
            differences.append(.alternativeVersion)
        }
        
        return differences
    }
}

enum VersionDifference: String, CaseIterable, Identifiable {
    case remastered = "Remastered"
    case deluxeEdition = "Deluxe"
    case lossless = "Lossless"
    case dolbyAtmos = "Dolby Atmos"
    case newer = "Newer"
    case explicitVersion = "Explicit"
    case cleanVersion = "Clean"
    case alternativeVersion = "Alternative"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .remastered, .deluxeEdition, .lossless, .dolbyAtmos:
            return .purple
        case .newer:
            return .green
        case .explicitVersion:
            return .red
        case .cleanVersion:
            return .blue
        case .alternativeVersion:
            return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .remastered:
            return "wand.and.stars"
        case .deluxeEdition:
            return "star.fill"
        case .lossless:
            return "hifi.speaker"
        case .dolbyAtmos:
            return "airpods.gen3"
        case .newer:
            return "clock.arrow.circlepath"
        case .explicitVersion:
            return "exclamationmark.square"
        case .cleanVersion:
            return "checkmark.square"
        case .alternativeVersion:
            return "shuffle"
        }
    }
}
