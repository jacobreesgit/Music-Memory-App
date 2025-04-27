//
//  SongsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI
import MediaPlayer

struct SongsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        NavigationView {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading songs...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                List {
                    ForEach(musicLibrary.songs, id: \.persistentID) { song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            SongRow(song: song)
                        }
                    }
                }
                .navigationTitle("Songs by Plays")
            }
        }
    }
}

struct SongDetailView: View {
    let song: MPMediaItem
    
    var body: some View {
        List {
            Section(header: DetailHeaderView(
                title: song.title ?? "Unknown",
                subtitle: song.artist ?? "Unknown",
                plays: song.playCount ?? 0,
                songCount: 1,
                artwork: song.artwork,
                isAlbum: false
            )) {
                // No related songs list as requested
            }
        }
        .navigationTitle(song.title ?? "Unknown")
        .navigationBarTitleDisplayMode(.inline)
    }
}
