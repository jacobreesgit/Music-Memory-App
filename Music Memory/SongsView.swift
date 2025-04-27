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
                ProgressView("Loading songs...")
            } else if !musicLibrary.hasAccess {
                Text("Please grant music library access")
            } else {
                List {
                    ForEach(musicLibrary.songs, id: \.persistentID) { song in
                        SongRow(song: song)
                    }
                }
                .navigationTitle("Songs by Plays")
            }
        }
    }
}
