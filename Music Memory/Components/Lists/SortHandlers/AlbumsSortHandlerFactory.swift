// Music Memory/Components/Lists/SortHandlers/AlbumsSortHandlerFactory.swift
import Foundation

enum AlbumSortOption: String, CaseIterable, Identifiable {
    case artist = "Artist"
    case dateAdded = "Date Added"
    case playCount = "Play Count"
    case recentlyPlayed = "Recently Played"
    case songCount = "Song Count"
    case title = "Title"
    
    var id: String { self.rawValue }
}

struct AlbumsSortHandlerFactory: SortHandlerFactory {
    typealias T = AlbumData
    typealias SortOption = AlbumSortOption
    
    func createSortHandler(for option: AlbumSortOption) -> ((AlbumData, AlbumData) -> Bool)? {
        switch option {
        case .playCount:
            return { $0.totalPlayCount > $1.totalPlayCount }
        case .title:
            return { $0.title < $1.title }
        case .artist:
            return { $0.artist < $1.artist }
        case .songCount:
            return { $0.songs.count > $1.songs.count }
        case .dateAdded:
            return {
                // Get the most recent date added for each album
                let date0 = $0.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.dateAdded }.max() ?? Date.distantPast
                return date0 > date1
            }
        case .recentlyPlayed:
            return {
                // Get the most recent played date for each album
                let date0 = $0.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                let date1 = $1.songs.compactMap { song in song.lastPlayedDate }.max() ?? Date.distantPast
                return date0 > date1
            }
        }
    }
}
