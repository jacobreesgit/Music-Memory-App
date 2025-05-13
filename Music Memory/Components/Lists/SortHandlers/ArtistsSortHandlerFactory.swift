// Music Memory/Components/Lists/SortHandlers/ArtistsSortHandlerFactory.swift
import Foundation

enum ArtistSortOption: String, CaseIterable, Identifiable {
    case dateAdded = "Date Added"
    case name = "Name"
    case playCount = "Play Count"
    case recentlyPlayed = "Recently Played"
    case songCount = "Song Count"
    
    var id: String { self.rawValue }
}

struct ArtistsSortHandlerFactory: SortHandlerFactory {
    typealias T = ArtistData
    typealias SortOption = ArtistSortOption
    
    func createSortHandler(for option: ArtistSortOption) -> ((ArtistData, ArtistData) -> Bool)? {
        switch option {
        case .playCount:
            return { $0.totalPlayCount > $1.totalPlayCount }
        case .name:
            return { $0.name < $1.name }
        case .songCount:
            return { $0.songs.count > $1.songs.count }
        case .dateAdded:
            return {
                // Get the most recent date added for each artist
                let date0 = $0.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                return date0 > date1
            }
        case .recentlyPlayed:
            return {
                // Get the most recent played date for each artist
                let date0 = $0.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                return date0 > date1
            }
        }
    }
}
