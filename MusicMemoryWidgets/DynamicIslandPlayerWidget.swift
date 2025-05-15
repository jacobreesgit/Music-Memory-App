// DynamicIslandPlayerWidget.swift
// This version has the NowPlayingAttributes definition removed

import WidgetKit
import SwiftUI
import ActivityKit

struct DynamicIslandPlayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NowPlayingAttributes.self) { context in
            // Dynamic Island - Live Activity display
            VStack(alignment: .leading) {
                HStack {
                    if let artworkData = context.state.artworkData,
                       let uiImage = UIImage(data: artworkData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .cornerRadius(4)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 22))
                            .frame(width: 40, height: 40)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Text(context.state.artist)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            Text("\(context.state.playCount) plays")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.purple)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18))
                            .frame(width: 36, height: 36)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(18)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Playback progress bar
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: geometry.size.width * context.state.playbackProgress, height: 2)
                }
                .frame(height: 2)
                .padding(.top, 4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded state
                DynamicIslandExpandedRegion(.leading) {
                    if let artworkData = context.state.artworkData,
                       let uiImage = UIImage(data: artworkData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 24))
                            .frame(width: 50, height: 50)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading) {
                        Text(context.state.title)
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(1)
                        
                        Text(context.state.artist)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            
                        Text("\(context.state.playCount) plays")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 20))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {}) {
                            Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .frame(width: 44, height: 44)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(22)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {}) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 20))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 3)
                                .cornerRadius(1.5)
                            
                            Rectangle()
                                .fill(Color.purple)
                                .frame(width: geometry.size.width * context.state.playbackProgress, height: 3)
                                .cornerRadius(1.5)
                        }
                    }
                    .frame(height: 3)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                
            } compactLeading: {
                if let artworkData = context.state.artworkData,
                   let uiImage = UIImage(data: artworkData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                Text("\(context.state.playCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.purple)
                    .padding(.trailing, 4)
                
                Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "music.note")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
        }
    }
}
