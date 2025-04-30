//
//  LibraryView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//

import SwiftUI
import MediaPlayer

struct LibraryView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var selectedTab = 0
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading your music...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            VStack(spacing: 0) {
                // Custom tab bar at the top
                HStack(spacing: 0) {
                    ForEach(0..<4) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(tabTitle(for: index))
                                    .font(.headline)
                                    .foregroundColor(selectedTab == index ? .red : .primary)
                                
                                // Indicator line
                                Rectangle()
                                    .fill(selectedTab == index ? Color.red : Color.clear)
                                    .frame(height: 2)
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
                
                // Tab content
                TabView(selection: $selectedTab) {
                    // Tracks tab
                    SongsView()
                        .tag(0)
                    
                    // Artists tab
                    ArtistsView()
                        .tag(1)
                    
                    // Albums tab
                    AlbumsView()
                        .tag(2)
                    
                    // Genres tab
                    GenresView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Tracks"
        case 1: return "Artists"
        case 2: return "Albums"
        case 3: return "Genres"
        default: return ""
        }
    }
}
