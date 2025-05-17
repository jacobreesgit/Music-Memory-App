// LibraryRow-matched DynamicIslandPlayerWidget.swift

import WidgetKit
import SwiftUI
import ActivityKit

struct DynamicIslandPlayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NowPlayingAttributes.self) { context in
            // Lock screen version - Precise match to LibraryRow
            HStack(spacing: 8) { // AppStyles.smallPadding
                // Rank number with exact styling from SongsSection
                Text("#\(context.state.songRank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.purple) // AppStyles.accentColor
                    .frame(width: 50, alignment: .leading)
                
                // Artwork with exact size from LibraryRow (50x50)
                ZStack {
                    RoundedRectangle(cornerRadius: 8) // AppStyles.cornerRadius
                        .fill(Color.secondary.opacity(0.2)) // AppStyles.secondaryColor
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }
                
                // Title and subtitle matching LibraryRow
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.title)
                        .font(.body) // AppStyles.bodyStyle
                        .lineLimit(1)
                    
                    Text(context.state.artist)
                        .font(.caption) // AppStyles.captionStyle
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Play count with chevron matching design
                HStack(spacing: 4) {
                    Text("\(context.state.playCount) plays")
                        .font(.subheadline) // AppStyles.playCountStyle
                        .foregroundColor(.purple) // AppStyles.accentColor
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 4) // Match LibraryRow padding
            .padding(.horizontal, 16)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded state
                DynamicIslandExpandedRegion(.leading) {
                    // Rank number with styling
                    HStack(spacing: 2) {
                        Text("#\(context.state.songRank)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.purple) // AppStyles.accentColor
                        
                        // Small artwork placeholder matching design
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "music.note")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Text(context.state.artist)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.playCount) plays")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
            } compactLeading: {
                // Rank number for compact view
                Text("#\(context.state.songRank)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            } compactTrailing: {
                // Play count
                Text("\(context.state.playCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.purple)
            } minimal: {
                // Minimal view
                Text("\(context.state.playCount)")
                    .font(.system(size: 10))
                    .foregroundColor(.purple)
            }
        }
    }
}
