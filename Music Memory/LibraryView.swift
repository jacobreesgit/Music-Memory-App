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
                // Custom tab bar at the top with smooth animation similar to screenshot
                HStack(spacing: 0) {
                    ForEach(0..<4) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(tabTitle(for: index))
                                    .font(.headline)
                                    .foregroundColor(selectedTab == index ? .red : .secondary)
                                    .fontWeight(selectedTab == index ? .bold : .regular)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)
                        }
                    }
                }
                .overlay(
                    // Moving underline indicator
                    GeometryReader { geo in
                        let tabWidth = geo.size.width / 4
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: tabWidth - 20, height: 2)
                            .offset(x: CGFloat(selectedTab) * tabWidth + 10)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    }
                    .frame(height: 2)
                    , alignment: .bottom
                )
                .padding(.top, 8)
                
                // Tab content - removed the animation modifier to match the main tab behavior
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
                // Removed the animation modifier that was causing the different behavior
            }
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Songs"
        case 1: return "Artists"
        case 2: return "Albums"
        case 3: return "Genres"
        default: return ""
        }
    }
}
