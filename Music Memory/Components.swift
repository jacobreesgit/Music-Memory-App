//
//  Components.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI
import MediaPlayer

struct AppStyles {
    static let accentColor = Color.purple
    static let backgroundColor = Color(UIColor.systemBackground)
    static let secondaryColor = Color.secondary.opacity(0.2)
    static let cornerRadius: CGFloat = 8
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    
    // Text styles
    static let titleStyle = Font.title
    static let subtitleStyle = Font.title2
    static let headlineStyle = Font.headline
    static let bodyStyle = Font.body
    static let captionStyle = Font.caption
    static let playCountStyle = Font.subheadline
}

struct TopItem {
    let title: String
    let subtitle: String
    let plays: Int
    let artwork: MPMediaItemArtwork?
}

struct TopItemsView<T, DestinationView: View>: View {
    let title: String
    let items: [T]
    let artwork: (T) -> MPMediaItemArtwork?
    let itemTitle: (T) -> String
    let itemSubtitle: (T) -> String
    let itemPlays: (T) -> Int
    let iconName: (T) -> String
    let destination: (T) -> DestinationView
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(AppStyles.headlineStyle)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        NavigationLink(destination: destination(item)) {
                            VStack {
                                // Artwork or placeholder
                                if let artwork = artwork(item) {
                                    Image(uiImage: artwork.image(at: CGSize(width: 100, height: 100)) ?? UIImage(systemName: "music.note")!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(AppStyles.cornerRadius)
                                } else {
                                    Image(systemName: iconName(item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .padding(10)
                                        .background(AppStyles.secondaryColor)
                                        .cornerRadius(AppStyles.cornerRadius)
                                }
                                
                                // Title
                                Text(itemTitle(item))
                                    .font(AppStyles.bodyStyle)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                
                                // Subtitle
                                Text(itemSubtitle(item))
                                    .font(AppStyles.captionStyle)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                // Play count
                                Text("\(itemPlays(item)) plays")
                                    .font(AppStyles.captionStyle)
                                    .foregroundColor(AppStyles.accentColor)
                            }
                            .frame(width: 100)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SongRow: View {
    let song: MPMediaItem
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork
            if let artwork = song.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "music.note")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                Image(systemName: "music.note")
                    .frame(width: 50, height: 50)
                    .background(AppStyles.secondaryColor)
                    .cornerRadius(AppStyles.cornerRadius)
            }
            
            // Title and Artist
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title ?? "Unknown")
                    .font(AppStyles.bodyStyle)
                    .lineLimit(1)
                
                Text(song.artist ?? "Unknown")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play count
            Text("\(song.playCount ?? 0)")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
        .padding(.vertical, 4)
    }
}

struct AlbumRow: View {
    let album: AlbumData
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork
            if let artwork = album.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "square.stack")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                Image(systemName: "square.stack")
                    .frame(width: 50, height: 50)
                    .background(AppStyles.secondaryColor)
                    .cornerRadius(AppStyles.cornerRadius)
            }
            
            // Title and Artist
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(AppStyles.bodyStyle)
                    .lineLimit(1)
                
                Text(album.artist)
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play count and song count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(album.totalPlayCount)")
                    .font(AppStyles.playCountStyle)
                    .foregroundColor(AppStyles.accentColor)
                
                Text("\(album.songs.count) songs")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ArtistRow: View {
    let artist: ArtistData
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artist icon (consistent with other rows)
            ZStack {
                Circle()
                    .fill(AppStyles.secondaryColor)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "music.mic")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }
            
            // Artist name and song count
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(AppStyles.bodyStyle)
                    .lineLimit(1)
                
                Text("\(artist.songs.count) songs")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play count
            Text("\(artist.totalPlayCount) plays")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
        }
        .padding(.vertical, 4)
    }
}

struct DetailHeaderView: View {
    let title: String
    let subtitle: String
    let plays: Int
    let songCount: Int
    let artwork: MPMediaItemArtwork?
    let isAlbum: Bool
    
    var body: some View {
        VStack(spacing: AppStyles.smallPadding) {
            // Artwork or placeholder
            if let artwork = artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 200, height: 200)) ?? UIImage(systemName: isAlbum ? "square.stack" : "music.mic")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                Image(systemName: isAlbum ? "square.stack" : "music.mic")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .padding(20)
                    .background(AppStyles.secondaryColor)
                    .cornerRadius(AppStyles.cornerRadius)
            }
            
            // Title
            Text(title)
                .font(AppStyles.subtitleStyle)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            // Subtitle (artist or "")
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(AppStyles.headlineStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            
            // Play count
            Text("Total Plays: \(plays)")
                .font(AppStyles.playCountStyle)
                .foregroundColor(AppStyles.accentColor)
                .padding(.top, 2)
            
            // Song count
            Text("\(songCount) songs")
                .font(AppStyles.captionStyle)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct LibraryAccessView: View {
    var body: some View {
        VStack(spacing: AppStyles.standardPadding) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(AppStyles.accentColor)
                .padding()
            
            Text("Music Memory needs access to your library")
                .font(AppStyles.headlineStyle)
                .multilineTextAlignment(.center)
            
            Text("Please allow access in Settings to see your music play counts")
                .font(AppStyles.bodyStyle)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(AppStyles.accentColor)
            .padding()
        }
        .padding()
    }
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: AppStyles.standardPadding) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text(message)
                .font(AppStyles.bodyStyle)
                .foregroundColor(.secondary)
        }
    }
}
