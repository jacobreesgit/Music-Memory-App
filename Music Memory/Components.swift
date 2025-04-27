//
//  Components.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI
import MediaPlayer

struct TopItemsView: View {
    let title: String
    let items: [TopItem]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        VStack {
                            if let artwork = item.artwork {
                                Image(uiImage: artwork.image(at: CGSize(width: 100, height: 100)) ?? UIImage(systemName: "music.note")!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)
                            } else {
                                Image(systemName: "music.mic")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .padding(10)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            Text(item.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Text("\(item.plays) plays")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        .frame(width: 100)
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
        HStack {
            if let artwork = song.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 40, height: 40)) ?? UIImage(systemName: "music.note")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
            } else {
                Image(systemName: "music.note")
                    .frame(width: 40, height: 40)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading) {
                Text(song.title ?? "Unknown")
                    .font(.body)
                Text(song.artist ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(song.playCount ?? 0)")
                .font(.subheadline)
                .foregroundColor(.purple)
        }
    }
}

struct AlbumRow: View {
    let album: AlbumData
    
    var body: some View {
        HStack {
            if let artwork = album.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 50, height: 50)) ?? UIImage(systemName: "square.stack")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(4)
            } else {
                Image(systemName: "square.stack")
                    .frame(width: 50, height: 50)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading) {
                Text(album.title)
                    .font(.body)
                Text(album.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(album.totalPlayCount)")
                    .font(.subheadline)
                    .foregroundColor(.purple)
                Text("\(album.songs.count) songs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AlbumHeaderView: View {
    let album: AlbumData
    
    var body: some View {
        VStack {
            if let artwork = album.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 200, height: 200)) ?? UIImage(systemName: "square.stack")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .cornerRadius(8)
            } else {
                Image(systemName: "square.stack")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .padding(20)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(album.title)
                .font(.title2)
            
            Text(album.artist)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Total Plays: \(album.totalPlayCount)")
                .font(.subheadline)
                .foregroundColor(.purple)
                .padding(.top, 2)
            
            Text("\(album.songs.count) songs")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct ArtistRow: View {
    let artist: ArtistData
    
    var body: some View {
        HStack {
            Image(systemName: "music.mic")
                .frame(width: 40, height: 40)
                .padding(5)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(25)
            
            VStack(alignment: .leading) {
                Text(artist.name)
                    .font(.body)
                Text("\(artist.songs.count) songs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(artist.totalPlayCount) plays")
                .font(.subheadline)
                .foregroundColor(.purple)
        }
    }
}
