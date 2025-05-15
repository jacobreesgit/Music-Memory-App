// MusicLibraryModel+Widget.swift
// Music Memory

import SwiftUI
import MediaPlayer
import WidgetKit

// Extension to MusicLibraryModel for widget data sharing
extension MusicLibraryModel {
    // Update widget data from the app
    func updateWidgetData() {
        // Process and save top songs
        let topSongs = self.filteredSongs.prefix(5).map { song in
            MusicHighlightsItem(
                id: song.persistentID.description,
                title: song.title ?? "Unknown",
                subtitle: song.artist ?? "Unknown",
                plays: song.playCount,
                artworkData: song.artwork?.image(at: CGSize(width: 100, height: 100))?.pngData()
            )
        }
        MusicHighlightsDataStore.shared.saveTopItems(Array(topSongs), forType: .songs)
        
        // Process and save top artists
        let topArtists = self.filteredArtists.prefix(5).map { artist in
            MusicHighlightsItem(
                id: artist.id,
                title: artist.name,
                subtitle: "\(artist.songs.count) songs",
                plays: artist.totalPlayCount,
                artworkData: artist.artwork?.image(at: CGSize(width: 100, height: 100))?.pngData()
            )
        }
        MusicHighlightsDataStore.shared.saveTopItems(Array(topArtists), forType: .artists)
        
        // Process and save top albums
        let topAlbums = self.filteredAlbums.prefix(5).map { album in
            MusicHighlightsItem(
                id: album.id,
                title: album.title,
                subtitle: album.artist,
                plays: album.totalPlayCount,
                artworkData: album.artwork?.image(at: CGSize(width: 100, height: 100))?.pngData()
            )
        }
        MusicHighlightsDataStore.shared.saveTopItems(Array(topAlbums), forType: .albums)
        
        // Process and save top playlists
        let topPlaylists = self.filteredPlaylists.prefix(5).map { playlist in
            MusicHighlightsItem(
                id: playlist.id,
                title: playlist.name,
                subtitle: "\(playlist.songs.count) songs",
                plays: playlist.totalPlayCount,
                artworkData: playlist.artwork?.image(at: CGSize(width: 100, height: 100))?.pngData()
            )
        }
        MusicHighlightsDataStore.shared.saveTopItems(Array(topPlaylists), forType: .playlists)
        
        // Refresh widgets
        WidgetCenter.shared.reloadTimelines(ofKind: "MusicHighlightsWidget")
    }
}
