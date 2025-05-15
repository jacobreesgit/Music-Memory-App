// DynamicIslandPlayerWidget.swift - Minimalist version focused on play count

import WidgetKit
import SwiftUI
import ActivityKit

struct DynamicIslandPlayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NowPlayingAttributes.self) { context in
            // Lock screen version - Keep simple
            HStack {
                Text("\(context.state.playCount)")
                    .font(.headline)
                    .foregroundColor(.purple)
                Text("plays")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded state - very minimal
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.state.title)")
                        .font(.caption)
                        .lineLimit(1)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    HStack {
                        Text("\(context.state.playCount)")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Text("plays")
                            .font(.caption)
                    }
                }
                
            } compactLeading: {
                // Title initial
                if let firstChar = context.state.title.first {
                    Text(String(firstChar))
                        .font(.caption)
                        .foregroundColor(.white)
                } else {
                    Text("M")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                // Just the play count - THIS IS THE KEY PART
                Text("\(context.state.playCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.purple)
            } minimal: {
                // Music note icon for minimal state
                Text(String(context.state.playCount))
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
        }
    }
}
