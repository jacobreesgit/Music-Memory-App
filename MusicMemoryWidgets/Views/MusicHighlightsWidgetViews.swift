// MusicHighlightsWidgetViews.swift - Updated for proper deep linking
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

// Small widget view (shows just top item) - with deep linking to detail view
struct SmallMusicHighlightsView: View {
    var entry: MusicHighlightsProvider.Entry
    
    var body: some View {
        ZStack {
            // Show only the #1 item
            if let topItem = entry.items.first {
                // Center content both horizontally and vertically
                VStack(spacing: 2) {  // Reduced spacing to match screenshot
                    // Artwork or placeholder - smaller size
                    ZStack(alignment: .topLeading) {
                        if let artworkData = topItem.artworkData,
                           let artwork = UIImage(data: artworkData) {
                            Image(uiImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)  // Smaller artwork
                                .cornerRadius(8)
                        } else {
                            // Placeholder with icon
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.2))
                                .frame(width: 80, height: 80)  // Smaller artwork
                            
                            Image(systemName: entry.configuration.contentType.iconName)
                                .font(.system(size: 20))  // Smaller icon
                                .foregroundColor(.purple)
                        }
                        
                        // Top rank badge
                        Text("#1")
                            .font(.system(size: 10, weight: .bold))  // Smaller font
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .cornerRadius(6)
                            .offset(x: -4, y: -4)  // Adjusted offset
                    }
                    .padding(.top, 4)
                    
                    // Title
                    Text(topItem.title)
                        .font(.system(size: 14, weight: .semibold))  // Smaller font
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                    
                    // Subtitle (artist name)
                    Text(topItem.subtitle)
                        .font(.system(size: 12))  // Smaller font
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .padding(.top, 1)
                    
                    // Play count
                    Text("\(topItem.plays) plays")
                        .font(.system(size: 12))  // Smaller font
                        .foregroundColor(.purple)
                        .padding(.top, 1)
                }
                // Center the content horizontally
                .frame(maxWidth: .infinity, alignment: .center)
                // Center the content vertically
                .frame(maxHeight: .infinity, alignment: .center)
                
                // Item-specific deep link - Ensure ID is valid
                .widgetURL(makeDeepLink(type: entry.configuration.contentType.rawValue, id: topItem.id))
            } else {
                // No items placeholder
                Text("No data available")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    // Helper to make proper deep links
    private func makeDeepLink(type: String, id: String) -> URL {
        // Make sure to properly escape components for URLs
        let baseURLString = "musicmemory://highlights"
        let encodedType = type.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? type
        let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        
        return URL(string: "\(baseURLString)/\(encodedType)/\(encodedId)") ??
               URL(string: "musicmemory://highlights")!
    }
}

struct MediumMusicHighlightsView: View {
    var entry: MusicHighlightsProvider.Entry
    
    var body: some View {
        // Get display title - always use the content type's display title
        let title = entry.configuration.contentType.displayTitle
        
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
                        // Item card - wrap each in a Link
                        Link(destination: makeDeepLink(type: entry.configuration.contentType.rawValue, id: item.id)) {
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
                                
                                // Play count - always shown now
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
        // Link for the whole widget goes to the category page
        .widgetURL(makeDeepLink(type: entry.configuration.contentType.rawValue, id: ""))
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    // Helper to make proper deep links
    private func makeDeepLink(type: String, id: String) -> URL {
        // Make sure to properly escape components for URLs
        let baseURLString = "musicmemory://highlights"
        let encodedType = type.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? type
        
        if id.isEmpty {
            return URL(string: "\(baseURLString)/\(encodedType)") ??
                   URL(string: "musicmemory://highlights")!
        } else {
            let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
            return URL(string: "\(baseURLString)/\(encodedType)/\(encodedId)") ??
                   URL(string: "musicmemory://highlights")!
        }
    }
}

// Large widget view (shows all 5 items)
struct LargeMusicHighlightsView: View {
    var entry: MusicHighlightsProvider.Entry
    
    var body: some View {
        // Get display title - always use the content type's display title
        let title = entry.configuration.contentType.displayTitle
            
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
                        Link(destination: makeDeepLink(type: entry.configuration.contentType.rawValue, id: item.id)) {
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
                                
                                // Play count - always shown now
                                Text("\(item.plays) plays")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.purple)
                            }
                            .padding(.horizontal, 16)
                        }
                        
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
        // Link for the whole widget goes to the category page
        .widgetURL(makeDeepLink(type: entry.configuration.contentType.rawValue, id: ""))
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    // Helper to make proper deep links
    private func makeDeepLink(type: String, id: String) -> URL {
        // Make sure to properly escape components for URLs
        let baseURLString = "musicmemory://highlights"
        let encodedType = type.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? type
        
        if id.isEmpty {
            return URL(string: "\(baseURLString)/\(encodedType)") ??
                   URL(string: "musicmemory://highlights")!
        } else {
            let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
            return URL(string: "\(baseURLString)/\(encodedType)/\(encodedId)") ??
                   URL(string: "musicmemory://highlights")!
        }
    }
}
