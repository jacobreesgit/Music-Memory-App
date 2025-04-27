//
//  ArtistsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI
import MediaPlayer

struct ArtistsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        NavigationView {
            if musicLibrary.isLoading {
                LoadingView(message: "Loading artists...")
            } else if !musicLibrary.hasAccess {
                LibraryAccessView()
            } else {
                List(musicLibrary.artists) { artist in
                    NavigationLink(destination: ArtistDetailView(artist: artist)) {
                        ArtistRow(artist: artist)
                    }
                }
                .navigationTitle("Artists by Plays")
            }
        }
    }
}

struct ArtistDetailView: View {
    let artist: ArtistData
    
    var body: some View {
        List {
            Section(header: DetailHeaderView(
                title: artist.name,
                subtitle: "",
                plays: artist.totalPlayCount,
                songCount: artist.songs.count,
                artwork: nil,
                isAlbum: false
            )) {
                ForEach(artist.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }, id: \.persistentID) { song in
                    SongRow(song: song)
                }
            }
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
