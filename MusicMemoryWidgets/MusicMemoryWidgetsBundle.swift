//
//  MusicMemoryWidgetsBundle.swift
//  MusicMemoryWidgets
//
//  Created by Jacob Rees on 13/05/2025.
//

import WidgetKit
import SwiftUI

@main
struct MusicMemoryWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Music Highlights widget (main widget)
        MusicHighlightsWidget()
        
        // Dynamic Island widget for now playing
        DynamicIslandPlayerLiveActivity()
    }
}
