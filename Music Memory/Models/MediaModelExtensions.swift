//  MediaModelExtensions.swift
//  Music Memory

import Foundation
import MediaPlayer

// MARK: - Song (MPMediaItem) Extension
extension MPMediaItem: MediaDetailDisplayable {
    var displayTitle: String {
        return title ?? "Unknown"
    }
    
    var displaySubtitle: String {
        return artist ?? "Unknown"
    }
    
    var totalPlayCount: Int {
        return playCount
    }
    
    var itemCount: Int {
        return 1 // A single song
    }
    
    func getMetadataItems() -> [MetadataItem] {
        var items: [MetadataItem] = [
            MetadataItem(iconName: "music.note.list", label: "Genre", value: genre ?? "Unknown"),
            MetadataItem(iconName: "clock", label: "Duration", value: formatDuration(playbackDuration)),
            MetadataItem(iconName: "calendar", label: "Release Date", value: formatDate(releaseDate)),
            MetadataItem(iconName: "play.circle", label: "Last Played", value: formatDate(lastPlayedDate)),
            MetadataItem(iconName: "plus.circle", label: "Date Added", value: formatDate(dateAdded))
        ]
        
        // Add optional metadata if available
        if let composer = composer, !composer.isEmpty {
            items.append(MetadataItem(iconName: "music.quarternote.3", label: "Composer", value: composer))
        }
        
        let trackNumber = albumTrackNumber
        if trackNumber > 0 {
            items.append(MetadataItem(iconName: "number", label: "Track", value: "\(trackNumber)"))
        }
        
        let discNumber = discNumber
        if discNumber > 0 {
            items.append(MetadataItem(iconName: "opticaldisc", label: "Disc", value: "\(discNumber)"))
        }
        
        let bpm = beatsPerMinute
        if bpm > 0 {
            items.append(MetadataItem(iconName: "metronome", label: "BPM", value: "\(bpm)"))
        }
        
        return items
    }
    
    private func formatDuration(_ timeInSeconds: TimeInterval) -> String {
        let minutes = Int(timeInSeconds / 60)
        let seconds = Int(timeInSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Album Extension
extension AlbumData: MediaDetailDisplayable {
    var displayTitle: String {
        return title
    }
    
    var displaySubtitle: String {
        return artist
    }
    
    var itemCount: Int {
        return songs.count
    }
    
    var isAlbumType: Bool {
        return true
    }
    
    func getMetadataItems() -> [MetadataItem] {
        return [
            MetadataItem(iconName: "calendar", label: "Released", value: releaseYear()),
            MetadataItem(iconName: "music.note.list", label: "Genre", value: primaryGenre),
            MetadataItem(iconName: "clock", label: "Duration", value: formatTotalDuration()),
            MetadataItem(iconName: "plus.circle", label: "Added", value: formatDate(dateAdded())),
            
            // Conditionally add composer if available from first song
            {
                if let song = songs.first, let composer = song.composer, !composer.isEmpty {
                    return MetadataItem(iconName: "music.quarternote.3", label: "Composer", value: composer)
                }
                return nil
            }(),
            
            // Number of discs
            {
                let discs = Set(songs.compactMap { $0.discNumber }).count
                if discs > 1 {
                    return MetadataItem(iconName: "opticaldisc", label: "Discs", value: "\(discs)")
                }
                return nil
            }(),
            
            // Average play count per song
            MetadataItem(iconName: "repeat", label: "Avg. Plays", value: "\(averagePlayCount) per song")
        ].compactMap { $0 } // Remove any nil items
    }
    
    // Helper for data display
    private func releaseYear() -> String {
        // Try to find a song with a release date
        if let firstSongWithDate = songs.first(where: { $0.releaseDate != nil }),
           let releaseDate = firstSongWithDate.releaseDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: releaseDate)
        }
        return "Unknown"
    }
    
    // Helper to format total duration
    private func formatTotalDuration() -> String {
        let totalSeconds = songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Helper to get date added to library
    private func dateAdded() -> Date? {
        // Find the earliest date added among all songs
        return songs.compactMap { $0.dateAdded }.min()
    }
}

// MARK: - Artist Extension
extension ArtistData: MediaDetailDisplayable {
    var displayTitle: String {
        return name
    }
    
    var displaySubtitle: String {
        return "" // Artists don't have a natural subtitle
    }
    
    var itemCount: Int {
        return songs.count
    }
    
    func getMetadataItems() -> [MetadataItem] {
        return [
            MetadataItem(iconName: "square.stack", label: "Albums", value: "\(albumCount)"),
            MetadataItem(iconName: "music.note.list", label: "Genres", value: topGenres().joined(separator: ", ")),
            MetadataItem(iconName: "clock", label: "Total Time", value: totalDuration()),
            MetadataItem(iconName: "plus.circle", label: "First Added", value: formatDate(dateRange().first)),
            
            // Top album info
            {
                let topAlbums = albumData().prefix(1)
                if let topAlbum = topAlbums.first {
                    return MetadataItem(iconName: "star", label: "Top Album", value: topAlbum.title)
                }
                return nil
            }(),
            
            {
                let topAlbums = albumData().prefix(1)
                if let topAlbum = topAlbums.first {
                    return MetadataItem(iconName: "music.note.tv", label: "Album Plays", value: "\(topAlbum.playCount)")
                }
                return nil
            }(),
            
            // Average plays per song
            MetadataItem(iconName: "repeat", label: "Avg. Plays", value: "\(averagePlayCount) per song"),
            
            // Most recent addition
            {
                if let lastAdded = dateRange().last {
                    return MetadataItem(iconName: "calendar", label: "Last Added", value: formatDate(lastAdded))
                }
                return nil
            }(),
            
            // Collection time range
            MetadataItem(iconName: "chart.line.uptrend.xyaxis", label: "In Collection",
                      value: "\(datesBetween(dateRange().first, dateRange().last)) days")
        ].compactMap { $0 } // Remove any nil items
    }
    
    // Helper to get total duration of all songs
    private func totalDuration() -> String {
        let totalSeconds = songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return String(format: "%dh %dm", hours, minutes)
    }
    
    // Helper to get first and last added song dates
    private func dateRange() -> (first: Date?, last: Date?) {
        let dates = songs.compactMap { $0.dateAdded }
        return (dates.min(), dates.max())
    }
    
    // Helper to calculate days between dates
    private func datesBetween(_ startDate: Date?, _ endDate: Date?) -> Int {
        guard let start = startDate, let end = endDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
    
    // Get album data for display (simplification of original method)
    private func albumData() -> [TopAlbumInfo] {
        // Group songs by album
        let songsByAlbum = Dictionary(grouping: songs) { song in
            song.albumTitle ?? "Unknown"
        }
        
        // Convert to array of album info
        return songsByAlbum.map { albumTitle, songs in
            let artwork = songs.first?.artwork
            let playCount = songs.reduce(0) { $0 + (($1.playCount ?? 0)) }
            
            return TopAlbumInfo(
                title: albumTitle,
                artwork: artwork,
                songCount: songs.count,
                playCount: playCount
            )
        }.sorted { $0.playCount > $1.playCount }
    }
    
    // Helper struct for album info
    struct TopAlbumInfo {
        let title: String
        let artwork: MPMediaItemArtwork?
        let songCount: Int
        let playCount: Int
    }
}

// MARK: - Genre Extension
extension GenreData: MediaDetailDisplayable {
    var displayTitle: String {
        return name
    }
    
    var displaySubtitle: String {
        return "" // Genres don't have a natural subtitle
    }
    
    var itemCount: Int {
        return songs.count
    }
    
    func getMetadataItems() -> [MetadataItem] {
        return [
            MetadataItem(iconName: "music.mic", label: "Artists", value: "\(artistCount)"),
            MetadataItem(iconName: "square.stack", label: "Albums", value: "\(albumCount)"),
            MetadataItem(iconName: "clock", label: "Total Time", value: totalDuration()),
            
            // Average play count per song
            MetadataItem(iconName: "repeat", label: "Avg. Plays", value: "\(averagePlayCount) per song")
        ]
    }
    
    private func totalDuration() -> String {
        let totalSeconds = songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return String(format: "%dh %dm", hours, minutes)
    }
}

// MARK: - Playlist Extension
extension PlaylistData: MediaDetailDisplayable {
    var displayTitle: String {
        return name
    }
    
    var displaySubtitle: String {
        return "" // Playlists don't have a natural subtitle
    }
    
    var itemCount: Int {
        return songs.count
    }
    
    func getMetadataItems() -> [MetadataItem] {
        return [
            MetadataItem(iconName: "square.stack", label: "Albums", value: "\(albumCount)"),
            MetadataItem(iconName: "music.note.list", label: "Top Genres", value: topGenres().joined(separator: ", ")),
            MetadataItem(iconName: "clock", label: "Total Time", value: formatTotalDuration()),
            MetadataItem(iconName: "plus.circle", label: "First Added", value: formatDate(dateRange().first)),
            
            // Most recent addition
            {
                if let lastAdded = dateRange().last {
                    return MetadataItem(iconName: "calendar", label: "Last Added", value: formatDate(lastAdded))
                }
                return nil
            }(),
            
            // Average plays per song
            MetadataItem(iconName: "repeat", label: "Avg. Plays", value: "\(averagePlayCount) per song")
        ].compactMap { $0 } // Remove any nil items
    }
    
    // Helper to format total duration
    private func formatTotalDuration() -> String {
        let totalSeconds = songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Helper to get first and last added song dates
    private func dateRange() -> (first: Date?, last: Date?) {
        let dates = songs.compactMap { $0.dateAdded }
        return (dates.min(), dates.max())
    }
}
