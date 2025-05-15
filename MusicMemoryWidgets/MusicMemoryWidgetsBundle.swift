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
        MusicMemoryWidgets()
        MusicMemoryWidgetsControl()
        MusicMemoryWidgetsLiveActivity()
        DynamicIslandPlayerLiveActivity() // Add this line to include the Dynamic Island widget
    }
}
