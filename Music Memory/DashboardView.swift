//
//  DashboardView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI
import MediaPlayer

struct DashboardView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        NavigationView {
            ZStack {
                if musicLibrary.isLoading {
                    ProgressView("Loading your music...")
                } else if !musicLibrary.hasAccess {
                    VStack {
                        Text("Music Memory needs access to your library")
                            .font(.headline)
                        Text("Please allow access in Settings")
                            .padding()
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Your Music Overview")
                                .font(.title)
                                .padding(.horizontal)
                            
                            TopItemsView(title: "Top Songs", items: musicLibrary.songs.prefix(5).map { 
                                TopItem(title: $0.title ?? "Unknown", subtitle: $0.artist ?? "Unknown", 
                                        plays: $0.playCount ?? 0, artwork: $0.artwork) 
                            })
                            
                            TopItemsView(title: "Top Albums", items: musicLibrary.albums.prefix(5).map { 
                                TopItem(title: $0.title, subtitle: $0.artist, 
                                        plays: $0.totalPlayCount, artwork: $0.artwork) 
                            })
                            
                            TopItemsView(title: "Top Artists", items: musicLibrary.artists.prefix(5).map { 
                                TopItem(title: $0.name, subtitle: "\($0.songs.count) songs", 
                                        plays: $0.totalPlayCount, artwork: nil) 
                            })
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}
