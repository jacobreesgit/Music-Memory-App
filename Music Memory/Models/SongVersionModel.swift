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
    
    func processSongs(_ songs: [MPMediaItem], includeRemixes: Bool = false) async {
        await MainActor.run {
            self.isProcessing = true
            self.processedItems = 0
            self.totalItems = songs.count
        }
        
        for (index, song) in songs.enumerated() {
            // Find versions for this song
            let versions = await AppleMusicManager.shared.findVersionsForSong(song, includeRemixes: includeRemixes)
            
            // If there are versions and we find a better one, add it to the replacement map
            if let bestReplacement = findBestReplacement(for: song, from: versions) {
                await MainActor.run {
                    self.replacementMap[song] = bestReplacement
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
    
    private func findBestReplacement(for librarySong: MPMediaItem, from catalogSongs: [Song]) -> Song? {
        guard !catalogSongs.isEmpty else { return nil }
        
        let songTitle = librarySong.title ?? ""
        let artistName = librarySong.artist ?? ""
        let albumTitle = librarySong.albumTitle ?? ""
        let libraryIsExplicit = librarySong.isExplicitItem
        
        // Keywords that might indicate improved versions
        let remasterKeywords = ["remaster", "anniversary", "deluxe", "special", "edition"]
        
        // Score each potential replacement
        var scoredReplacements: [(song: Song, score: Int)] = []
        
        for catalogSong in catalogSongs {
            var score = 0
            
            // Exact title match is good
            if catalogSong.title.lowercased() == songTitle.lowercased() {
                score += 20
            }
            
            // Exact artist match is good
            if catalogSong.artistName.lowercased() == artistName.lowercased() {
                score += 15
            }
            
            // If album titles match, that's a small bonus
            if let catalogAlbum = catalogSong.albumTitle,
               catalogAlbum.lowercased() == albumTitle.lowercased() {
                score += 5
            }
            
            // Matching explicit status is good
            if catalogSong.contentRating == .explicit && libraryIsExplicit {
                score += 10
            } else if catalogSong.contentRating != .explicit && !libraryIsExplicit {
                score += 10
            }
            
            // Higher quality audio is better
            if catalogSong.audioVariants.contains(.lossless) {
                score += 8
            }
            if catalogSong.audioVariants.contains(.dolbyAtmos) {
                score += 5
            }
            
            // Newer release date is better
            if let releaseDate = catalogSong.releaseDate,
               let libraryReleaseDate = librarySong.releaseDate,
               releaseDate > libraryReleaseDate {
                score += 7
            }
            
            // Check for remaster keywords
            if remasterKeywords.contains(where: { keyword in
                catalogSong.title.lowercased().contains(keyword) ||
                (catalogSong.albumTitle?.lowercased().contains(keyword) ?? false)
            }) {
                score += 12
            }
            
            // We prefer original albums over compilations
            if catalogSong.albumTitle?.lowercased().contains("compilation") ?? false {
                score -= 5
            }
            
            scoredReplacements.append((catalogSong, score))
        }
        
        // Sort by score and return the best match if it's significantly better
        let sortedReplacements = scoredReplacements.sorted { $0.score > $1.score }
        
        // Must have a minimum score to be considered a good replacement
        if let bestMatch = sortedReplacements.first, bestMatch.score > 25 {
            return bestMatch.song
        }
        
        return nil
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
        if catalogItem.audioVariants.contains(.lossless) {
            differences.append(.lossless)
        }
        
        if catalogItem.audioVariants.contains(.dolbyAtmos) {
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
