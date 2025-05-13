// Music Memory/Components/Lists/SortHandlers/SongsSortHandlerFactory.swift
import MediaPlayer

enum SongSortOption: String, CaseIterable, Identifiable {
    case artist = "Artist"
    case dateAdded = "Date Added"
    case duration = "Duration"
    case playCount = "Play Count"
    case recentlyPlayed = "Recently Played"
    case title = "Title"
    
    var id: String { self.rawValue }
}

struct SongsSortHandlerFactory: SortHandlerFactory {
    typealias T = MPMediaItem
    typealias SortOption = SongSortOption
    
    func createSortHandler(for option: SongSortOption) -> ((MPMediaItem, MPMediaItem) -> Bool)? {
        switch option {
        case .playCount:
            return { $0.playCount > $1.playCount }
        case .title:
            return { ($0.title ?? "") < ($1.title ?? "") }
        case .artist:
            return { ($0.artist ?? "") < ($1.artist ?? "") }
        case .dateAdded:
            return {
                // Fixed version - directly compare dates since they're not optional
                return $0.dateAdded > $1.dateAdded
            }
        case .duration:
            return { $0.playbackDuration > $1.playbackDuration }
        case .recentlyPlayed:
            return {
                let date0 = $0.lastPlayedDate ?? .distantPast
                let date1 = $1.lastPlayedDate ?? .distantPast
                return date0 > date1
            }
        }
    }
}
