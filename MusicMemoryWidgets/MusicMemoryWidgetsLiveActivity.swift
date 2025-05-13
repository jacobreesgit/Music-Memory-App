//
//  MusicMemoryWidgetsLiveActivity.swift
//  MusicMemoryWidgets
//
//  Created by Jacob Rees on 13/05/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MusicMemoryWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MusicMemoryWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MusicMemoryWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MusicMemoryWidgetsAttributes {
    fileprivate static var preview: MusicMemoryWidgetsAttributes {
        MusicMemoryWidgetsAttributes(name: "World")
    }
}

extension MusicMemoryWidgetsAttributes.ContentState {
    fileprivate static var smiley: MusicMemoryWidgetsAttributes.ContentState {
        MusicMemoryWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MusicMemoryWidgetsAttributes.ContentState {
         MusicMemoryWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MusicMemoryWidgetsAttributes.preview) {
   MusicMemoryWidgetsLiveActivity()
} contentStates: {
    MusicMemoryWidgetsAttributes.ContentState.smiley
    MusicMemoryWidgetsAttributes.ContentState.starEyes
}
