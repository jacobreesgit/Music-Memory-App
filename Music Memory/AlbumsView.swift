//
//  AlbumsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI
import MediaPlayer

struct AlbumsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        NavigationView {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading albums...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                List(musicLibrary.albums) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        AlbumRow(album: album)
                    }
                }
                .navigationTitle("Albums by Plays")
            }
        }
    }
}

struct AlbumDetailView: View {
    let album: AlbumData
    
    var body: some View {
        List {
            Section(header: DetailHeaderView(
                title: album.title,
                subtitle: album.artist,
                plays: album.totalPlayCount,
                songCount: album.songs.count,
                artwork: album.artwork,
                isAlbum: true
            )) {
                ForEach(album.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }, id: \.persistentID) { song in
                    SongRow(song: song)
                }
            }
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
