//
//  AppIntent.swift
//  MusicMemoryWidgets
//
//  Created by Jacob Rees on 13/05/2025.
//

import WidgetKit
import AppIntents

// Keep this for existing widgets
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription {
        IntentDescription("This is an example widget.")
    }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

// Add this for the Dynamic Island
struct NowPlayingConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Now Playing Configuration" }
    static var description: IntentDescription {
        IntentDescription("Configure the Now Playing display in Dynamic Island")
    }
}
