// Music Memory/Components/Lists/SortHandlers/GenresSortHandlerFactory.swift
import Foundation

enum GenreSortOption: String, CaseIterable, Identifiable {
    case dateAdded = "Date Added"
    case name = "Name"
    case playCount = "Play Count"
    case recentlyPlayed = "Recently Played"
    case songCount = "Song Count"
    
    var id: String { self.rawValue }
}

struct GenresSortHandlerFactory: SortHandlerFactory {
    typealias T = GenreData
    typealias SortOption = GenreSortOption
    
    func createSortHandler(for option: GenreSortOption) -> ((GenreData, GenreData) -> Bool)? {
        switch option {
        case .playCount:
            return { $0.totalPlayCount > $1.totalPlayCount }
        case .name:
            return { $0.name < $1.name }
        case .songCount:
            return { $0.songs.count > $1.songs.count }
        case .dateAdded:
            return {
                // Get the most recent date added for each genre
                let date0 = $0.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                return date0 > date1
            }
        case .recentlyPlayed:
            return {
                // Get the most recent played date for each genre
                let date0 = $0.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                return date0 > date1
            }
        }
    }
}
