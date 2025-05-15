// MusicHighlightsWidgetViews.swift
// MusicMemoryWidgets

import WidgetKit
import SwiftUI

// Main widget view that handles different sizes
struct MusicHighlightsWidgetEntryView: View {
    var entry: MusicHighlightsProvider.Entry
    @Environment(\.widgetFamily) private var widgetFamily
    
    var body: some View {
        // Choose view based on widget size
        switch widgetFamily {
        case .systemSmall:
            SmallMusicHighlightsView(entry: entry)
        case .systemMedium:
            MediumMusicHighlightsView(entry: entry)
        case .systemLarge:
            LargeMusicHighlightsView(entry: entry)
        default:
            // Fallback for any other sizes
            MediumMusicHighlightsView(entry: entry)
        }
    }
}

// Small widget view (shows just top item)
struct SmallMusicHighlightsView: View {
    var entry: MusicHighlightsProvider.Entry
    
    var body: some View {
        // Get display title
        let title = entry.configuration.customTitle.isEmpty ?
            entry.configuration.contentType.displayTitle :
            entry.configuration.customTitle
        
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: entry.configuration.contentType.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(.purple)
                
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            // Show only the #1 item
            if let topItem = entry.items.first {
                Spacer()
                
                // Center main content
                VStack(spacing: 6) {
                    // Artwork or placeholder
                    ZStack {
                        if let artworkData = topItem.artworkData,
                           let artwork = UIImage(data: artworkData) {
                            Image(uiImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .cornerRadius(8)
                        } else {
                            // Placeholder with icon
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.2))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: entry.configuration.contentType.iconName)
                                .font(.system(size: 24))
                                .foregroundColor(.purple)
                        }
                        
                        // Top rank badge
                        VStack {
                            HStack {
                                Text("#1")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.purple)
                                    .cornerRadius(4)
                                
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(2)
                        .frame(width: 70, height: 70)
                    }
                    
                    // Title
                    Text(topItem.title)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    // Subtitle
                    Text(topItem.subtitle)
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    
                    // Play count if enabled
                    if entry.configuration.showPlayCounts {
                        Text("\(topItem.plays) plays")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            } else {
                // No items placeholder
                Text("No data available")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .widgetURL(URL(string: "musicmemory://highlights/\(entry.configuration.contentType.rawValue)"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumMusicHighlightsView: View {
    var entry: MusicHighlightsProvider.Entry
    
    var body: some View {
        // Get display title
        let title = entry.configuration.customTitle.isEmpty ?
            entry.configuration.contentType.displayTitle :
            entry.configuration.customTitle
        
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: entry.configuration.contentType.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(.purple)
                
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Items in grid layout (top 3) instead of ScrollView
            if !entry.items.isEmpty {
                HStack(spacing: 12) {
                    ForEach(Array(entry.items.prefix(3).enumerated()), id: \.element.id) { index, item in
                        // Item card
                        VStack(spacing: 4) {
                            // Artwork or placeholder
                            ZStack {
                                if let artworkData = item.artworkData,
                                   let artwork = UIImage(data: artworkData) {
                                    Image(uiImage: artwork)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                } else {
                                    // Placeholder with icon
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.purple.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: entry.configuration.contentType.iconName)
                                        .font(.system(size: 20))
                                        .foregroundColor(.purple)
                                }
                                
                                // Rank badge
                                VStack {
                                    HStack {
                                        Text("#\(index + 1)")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.purple)
                                            .cornerRadius(4)
                                        
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .padding(2)
                                .frame(width: 60, height: 60)
                            }
                            
                            // Title
                            Text(item.title)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .frame(width: 60)
                            
                            // Subtitle
                            Text(item.subtitle)
                                .font(.system(size: 9))
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                                .frame(width: 60)
                            
                            // Play count if enabled
                            if entry.configuration.showPlayCounts {
                                Text("\(item.plays) plays")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.purple)
                                    .frame(width: 60)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
            } else {
                // No items placeholder
                Text("No data available")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .widgetURL(URL(string: "musicmemory://highlights/\(entry.configuration.contentType.rawValue)"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// Large widget view (shows all 5 items)
struct LargeMusicHighlightsView: View {
    var entry: MusicHighlightsProvider.Entry
    
    var body: some View {
        // Get display title
        let title = entry.configuration.customTitle.isEmpty ?
            entry.configuration.contentType.displayTitle :
            entry.configuration.customTitle
            
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: entry.configuration.contentType.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            if !entry.items.isEmpty {
                // List layout (top 5)
                VStack(spacing: 12) {
                    ForEach(Array(entry.items.prefix(5).enumerated()), id: \.element.id) { index, item in
                        // Row layout
                        HStack(spacing: 12) {
                            // Rank number
                            Text("#\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.purple)
                                .frame(width: 30, alignment: .center)
                            
                            // Artwork or placeholder
                            if let artworkData = item.artworkData,
                               let artwork = UIImage(data: artworkData) {
                                Image(uiImage: artwork)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(6)
                            } else {
                                // Placeholder with icon
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.purple.opacity(0.2))
                                        .frame(width: 48, height: 48)
                                    
                                    Image(systemName: entry.configuration.contentType.iconName)
                                        .font(.system(size: 20))
                                        .foregroundColor(.purple)
                                }
                            }
                            
                            // Title and subtitle
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                                
                                Text(item.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Play count if enabled
                            if entry.configuration.showPlayCounts {
                                Text("\(item.plays) plays")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Divider for all but the last item
                        if index < entry.items.count - 1 && index < 4 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
            } else {
                // No items placeholder
                Text("No data available")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .widgetURL(URL(string: "musicmemory://highlights/\(entry.configuration.contentType.rawValue)"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
