//
//  ContentView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }
            
            SongsView()
                .tabItem {
                    Label("Songs", systemImage: "music.note")
                }
            
            AlbumsView()
                .tabItem {
                    Label("Albums", systemImage: "square.stack")
                }
            
            ArtistsView()
                .tabItem {
                    Label("Artists", systemImage: "music.mic")
                }
        }
        .accentColor(AppStyles.accentColor)
    }
}
