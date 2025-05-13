// NowPlayingBar.swift - Complete rewrite
import SwiftUI
import MediaPlayer

struct NowPlayingBar: View {
    @ObservedObject var nowPlayingModel: NowPlayingModel
    @EnvironmentObject var musicLibrary: MusicLibraryModel
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
                // Artwork with loading state
                ZStack {
                    Rectangle()
                        .fill(AppStyles.secondaryColor)
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)

                    if nowPlayingModel.isLoadingArtwork {
                        ProgressView()
                            .scaleEffect(0.7)
                            .transition(.opacity)
                    } else {
                        artworkView
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: nowPlayingModel.isLoadingArtwork)

                VStack(alignment: .leading, spacing: 1) {
                    Text(nowPlayingModel.currentSong?.title ?? "Unknown")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(nowPlayingModel.currentSong?.artist ?? "Unknown Artist")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        if let plays = getSongPlayCount() {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text("\(plays) plays")
                                .font(.caption2)
                                .foregroundColor(AppStyles.accentColor)
                                .lineLimit(1)
                        }
                    }
                }
                .id(nowPlayingModel.currentSong?.persistentID ?? 0)

                Spacer()

                HStack(spacing: 18) {
                    Button(action: {
                        nowPlayingModel.previousTrack()
                        let feedback = UIImpactFeedbackGenerator(style: .light)
                        feedback.impactOccurred()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }

                    Button(action: {
                        nowPlayingModel.togglePlayPause()
                        let feedback = UIImpactFeedbackGenerator(style: .medium)
                        feedback.impactOccurred()
                    }) {
                        Image(systemName: nowPlayingModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }

                    Button(action: {
                        nowPlayingModel.nextTrack()
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
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingFullPlayer = true
        }
        .transition(.move(edge: .bottom))
        .animation(.easeInOut(duration: 0.3), value: nowPlayingModel.currentSong != nil)
    }
    
    // Artwork view with proper source handling
    private var artworkView: some View {
        Group {
            if let artwork = nowPlayingModel.artworkImage {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
                    .transition(.opacity)
                    .id("artwork_\(nowPlayingModel.currentSong?.persistentID ?? 0)")
            } else {
                // Fallback to placeholder
                Image(systemName: "music.note")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .transition(.opacity)
            }
        }
    }

    private func getSongPlayCount() -> Int? {
        guard let currentSong = nowPlayingModel.currentSong else { return nil }
        return musicLibrary.songs.first { $0.persistentID == currentSong.persistentID }?.playCount
    }
}
