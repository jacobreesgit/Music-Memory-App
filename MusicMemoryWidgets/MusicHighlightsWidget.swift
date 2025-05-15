// MusicHighlightsWidget.swift
// MusicMemoryWidgets

import WidgetKit
import SwiftUI
import AppIntents

struct MusicHighlightsProvider: AppIntentTimelineProvider {
    // Placeholder data for widget gallery and previews
    func placeholder(in context: Context) -> MusicHighlightsEntry {
        // Create some sample items
        let sampleItems = [
            MusicHighlightsItem(id: "1", title: "Song Title", subtitle: "Artist Name", plays: 128, artworkData: nil),
            MusicHighlightsItem(id: "2", title: "Another Song", subtitle: "Another Artist", plays: 92, artworkData: nil),
            MusicHighlightsItem(id: "3", title: "Third Song", subtitle: "Third Artist", plays: 75, artworkData: nil),
            MusicHighlightsItem(id: "4", title: "Fourth Song", subtitle: "Fourth Artist", plays: 61, artworkData: nil),
            MusicHighlightsItem(id: "5", title: "Fifth Song", subtitle: "Fifth Artist", plays: 53, artworkData: nil)
        ]
        
        return MusicHighlightsEntry(
            date: Date(),
            configuration: MusicHighlightsIntent(),
            items: sampleItems
        )
    }
    
    // Preview data for widget gallery
    func snapshot(for configuration: MusicHighlightsIntent, in context: Context) async -> MusicHighlightsEntry {
        // Create example items for preview
        let contentType = configuration.contentType
        let previewItems = generatePlaceholderItems(for: contentType)
        
        return MusicHighlightsEntry(
            date: Date(),
            configuration: configuration,
            items: previewItems
        )
    }
    
    // Timeline generation for the widget
    func timeline(for configuration: MusicHighlightsIntent, in context: Context) async -> Timeline<MusicHighlightsEntry> {
        // Get stored items for the selected content type
        let contentType = configuration.contentType
        let items = MusicHighlightsDataStore.shared.getTopItems(forType: contentType)
        
        // If we have no items, use placeholders
        let finalItems = items.isEmpty ? generatePlaceholderItems(for: contentType) : items
        
        // Create entry with fetched or placeholder data
        let entry = MusicHighlightsEntry(
            date: Date(),
            configuration: configuration,
            items: finalItems
        )
        
        // Refresh every hour or when last updated is too old
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    // Generate placeholder data based on content type
    private func generatePlaceholderItems(for contentType: MusicContentType) -> [MusicHighlightsItem] {
        switch contentType {
        case .songs:
            return [
                MusicHighlightsItem(id: "1", title: "Bohemian Rhapsody", subtitle: "Queen", plays: 128, artworkData: nil),
                MusicHighlightsItem(id: "2", title: "Blinding Lights", subtitle: "The Weeknd", plays: 92, artworkData: nil),
                MusicHighlightsItem(id: "3", title: "Billie Jean", subtitle: "Michael Jackson", plays: 75, artworkData: nil),
                MusicHighlightsItem(id: "4", title: "Shape of You", subtitle: "Ed Sheeran", plays: 61, artworkData: nil),
                MusicHighlightsItem(id: "5", title: "Don't Stop Believin'", subtitle: "Journey", plays: 53, artworkData: nil)
            ]
        case .artists:
            return [
                MusicHighlightsItem(id: "1", title: "Taylor Swift", subtitle: "42 songs", plays: 230, artworkData: nil),
                MusicHighlightsItem(id: "2", title: "The Beatles", subtitle: "28 songs", plays: 188, artworkData: nil),
                MusicHighlightsItem(id: "3", title: "Drake", subtitle: "35 songs", plays: 175, artworkData: nil),
                MusicHighlightsItem(id: "4", title: "Adele", subtitle: "15 songs", plays: 154, artworkData: nil),
                MusicHighlightsItem(id: "5", title: "Coldplay", subtitle: "22 songs", plays: 123, artworkData: nil)
            ]
        case .albums:
            return [
                MusicHighlightsItem(id: "1", title: "Abbey Road", subtitle: "The Beatles", plays: 115, artworkData: nil),
                MusicHighlightsItem(id: "2", title: "Back In Black", subtitle: "AC/DC", plays: 98, artworkData: nil),
                MusicHighlightsItem(id: "3", title: "Thriller", subtitle: "Michael Jackson", plays: 87, artworkData: nil),
                MusicHighlightsItem(id: "4", title: "1989", subtitle: "Taylor Swift", plays: 76, artworkData: nil),
                MusicHighlightsItem(id: "5", title: "Rumours", subtitle: "Fleetwood Mac", plays: 69, artworkData: nil)
            ]
        case .playlists:
            return [
                MusicHighlightsItem(id: "1", title: "Workout Mix", subtitle: "32 songs", plays: 142, artworkData: nil),
                MusicHighlightsItem(id: "2", title: "Road Trip", subtitle: "45 songs", plays: 115, artworkData: nil),
                MusicHighlightsItem(id: "3", title: "Study Session", subtitle: "28 songs", plays: 94, artworkData: nil),
                MusicHighlightsItem(id: "4", title: "Chill Vibes", subtitle: "40 songs", plays: 78, artworkData: nil),
                MusicHighlightsItem(id: "5", title: "Party Playlist", subtitle: "37 songs", plays: 63, artworkData: nil)
            ]
        }
    }
}

// Entry struct that holds the data for rendering a widget
struct MusicHighlightsEntry: TimelineEntry {
    let date: Date
    let configuration: MusicHighlightsIntent
    let items: [MusicHighlightsItem]
}

// Main widget structure
struct MusicHighlightsWidget: Widget {
    let kind: String = "MusicHighlightsWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: MusicHighlightsIntent.self,
            provider: MusicHighlightsProvider()
        ) { entry in
            MusicHighlightsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Music Highlights")
        .description("Show your top played music at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Preview helpers
extension MusicHighlightsIntent {
    // Songs configuration
    fileprivate static var songs: MusicHighlightsIntent {
        let intent = MusicHighlightsIntent()
        intent.contentType = .songs
        intent.showPlayCounts = true
        return intent
    }
    
    // Artists configuration
    fileprivate static var artists: MusicHighlightsIntent {
        let intent = MusicHighlightsIntent()
        intent.contentType = .artists
        intent.showPlayCounts = true
        return intent
    }
    
    // Albums configuration
    fileprivate static var albums: MusicHighlightsIntent {
        let intent = MusicHighlightsIntent()
        intent.contentType = .albums
        intent.showPlayCounts = false
        return intent
    }
}

// Preview
#Preview(as: .systemSmall) {
    MusicHighlightsWidget()
} timeline: {
    let songsItems = [
        MusicHighlightsItem(id: "1", title: "Bohemian Rhapsody", subtitle: "Queen", plays: 128, artworkData: nil),
        MusicHighlightsItem(id: "2", title: "Blinding Lights", subtitle: "The Weeknd", plays: 92, artworkData: nil)
    ]
    MusicHighlightsEntry(date: .now, configuration: .songs, items: songsItems)
}

#Preview(as: .systemMedium) {
    MusicHighlightsWidget()
} timeline: {
    let artistItems = [
        MusicHighlightsItem(id: "1", title: "Taylor Swift", subtitle: "42 songs", plays: 230, artworkData: nil),
        MusicHighlightsItem(id: "2", title: "The Beatles", subtitle: "28 songs", plays: 188, artworkData: nil),
        MusicHighlightsItem(id: "3", title: "Drake", subtitle: "35 songs", plays: 175, artworkData: nil)
    ]
    MusicHighlightsEntry(date: .now, configuration: .artists, items: artistItems)
}

#Preview(as: .systemLarge) {
    MusicHighlightsWidget()
} timeline: {
    let albumItems = [
        MusicHighlightsItem(id: "1", title: "Abbey Road", subtitle: "The Beatles", plays: 115, artworkData: nil),
        MusicHighlightsItem(id: "2", title: "Back In Black", subtitle: "AC/DC", plays: 98, artworkData: nil),
        MusicHighlightsItem(id: "3", title: "Thriller", subtitle: "Michael Jackson", plays: 87, artworkData: nil),
        MusicHighlightsItem(id: "4", title: "1989", subtitle: "Taylor Swift", plays: 76, artworkData: nil),
        MusicHighlightsItem(id: "5", title: "Rumours", subtitle: "Fleetwood Mac", plays: 69, artworkData: nil)
    ]
    MusicHighlightsEntry(date: .now, configuration: .albums, items: albumItems)
}
