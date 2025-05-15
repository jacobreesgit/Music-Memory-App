// MusicHighlightsIntent.swift
// MusicMemoryWidgets

import AppIntents
import WidgetKit
import SwiftUI

// Configuration options for the Music Highlights widget
struct MusicHighlightsIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Music Highlights Configuration"
    static var description = IntentDescription("Configure what music stats to display")
    
    // Content type selection
    @Parameter(title: "Content Type", default: .songs)
    var contentType: MusicContentType
    }
