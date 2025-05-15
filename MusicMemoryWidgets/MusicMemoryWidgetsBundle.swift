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
        // Add our new Music Highlights widget
        MusicHighlightsWidget()
        
        // Keep control widget
        MusicMemoryWidgetsControl()
        
        // Keep Live Activity widgets
        MusicMemoryWidgetsLiveActivity()
        DynamicIslandPlayerLiveActivity()
    }
}
