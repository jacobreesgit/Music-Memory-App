//
//  NowPlayingBar.swift
//  Music Memory
//
//  Created on 13/05/2025.
//

import SwiftUI
import MediaPlayer

struct NowPlayingBar: View {
    @ObservedObject var nowPlayingModel: NowPlayingModel
    @State private var showingFullPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(AppStyles.accentColor)
                    .frame(width: geometry.size.width * nowPlayingModel.playbackProgress, height: 2)
                    .animation(.linear(duration: 0.5), value: nowPlayingModel.playbackProgress)
            }
            .frame(height: 2)
            
            // Main content
            HStack(spacing: 12) {
                // Artwork - updated to use fetched artwork when local artwork isn't available
                if let artwork = nowPlayingModel.currentSong?.artwork {
                    // Use local artwork if available
                    Image(uiImage: artwork.image(at: CGSize(width: 40, height: 40)) ?? UIImage(systemName: "music.note")!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                } else if let fetchedArtwork = nowPlayingModel.fetchedArtwork {
                    // Use fetched artwork if available
                    Image(uiImage: fetchedArtwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                } else {
                    // Fallback to placeholder
                    ZStack {
                        Rectangle()
                            .fill(AppStyles.secondaryColor)
                            .frame(width: 40, height: 40)
                            .cornerRadius(4)
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                }
                
                // Song info
                VStack(alignment: .leading, spacing: 1) {
                    Text(nowPlayingModel.currentSong?.title ?? "Unknown")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(nowPlayingModel.currentSong?.artist ?? "Unknown Artist")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Playback controls
                HStack(spacing: 18) {
                    Button(action: {
                        nowPlayingModel.previousTrack()
                        // Add light haptic feedback
                        let feedback = UIImpactFeedbackGenerator(style: .light)
                        feedback.impactOccurred()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        nowPlayingModel.togglePlayPause()
                        // Add medium haptic feedback
                        let feedback = UIImpactFeedbackGenerator(style: .medium)
                        feedback.impactOccurred()
                    }) {
                        Image(systemName: nowPlayingModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        nowPlayingModel.nextTrack()
                        // Add light haptic feedback
                        let feedback = UIImpactFeedbackGenerator(style: .light)
                        feedback.impactOccurred()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(UIColor.systemBackground))
            
            Divider()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // For future implementation: Navigate to full player view
            showingFullPlayer = true
        }
        .transition(.move(edge: .bottom))
        .animation(.easeInOut(duration: 0.3), value: nowPlayingModel.currentSong != nil)
    }
}

struct NowPlayingBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            NowPlayingBar(nowPlayingModel: NowPlayingModel())
        }
        .previewLayout(.sizeThatFits)
    }
}
