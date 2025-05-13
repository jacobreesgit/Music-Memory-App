// NowPlayingBar.swift - Updated to match LibraryRow design
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
            HStack(spacing: AppStyles.smallPadding) {
                // Artwork with loading state - increased to match LibraryRow
                ZStack {
                    Rectangle()
                        .fill(AppStyles.secondaryColor)
                        .frame(width: 50, height: 50)
                        .cornerRadius(AppStyles.cornerRadius)

                    if nowPlayingModel.isLoadingArtwork {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if let artwork = nowPlayingModel.artworkImage {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(AppStyles.cornerRadius)
                            .id("artwork_\(nowPlayingModel.currentSong?.persistentID ?? 0)")
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: nowPlayingModel.isLoadingArtwork)
                .animation(.easeInOut(duration: 0.2), value: nowPlayingModel.artworkImage != nil)

                // Track info - updated to match LibraryRow font styles
                VStack(alignment: .leading, spacing: 2) {
                    Text(nowPlayingModel.currentSong?.title ?? "Unknown")
                        .font(AppStyles.bodyStyle)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(nowPlayingModel.currentSong?.artist ?? "Unknown Artist")
                            .font(AppStyles.captionStyle)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        if let plays = getSongPlayCount() {
                            Text("•")
                                .font(AppStyles.captionStyle)
                                .foregroundColor(.secondary)

                            Text("\(plays) plays")
                                .font(AppStyles.captionStyle)
                                .foregroundColor(AppStyles.accentColor)
                                .lineLimit(1)
                        }
                    }
                }
                .id("info_\(nowPlayingModel.currentSong?.persistentID ?? 0)")

                Spacer()

                // Player controls
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
            .padding(.vertical, 8) // Adjusted to better match LibraryRow's height with padding of 4
            .background(Color(UIColor.systemBackground))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingFullPlayer = true
        }
        .transition(.move(edge: .bottom))
        .animation(.easeInOut(duration: 0.3), value: nowPlayingModel.currentSong != nil)
    }

    private func getSongPlayCount() -> Int? {
        guard let currentSong = nowPlayingModel.currentSong else { return nil }
        return musicLibrary.songs.first { $0.persistentID == currentSong.persistentID }?.playCount
    }
}
