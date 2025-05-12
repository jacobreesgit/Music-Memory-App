//
//  RecentlyPlayedSongsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 12/05/2025.
//

import SwiftUI

struct RecentlyPlayedSongsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(alignment: .leading, spacing: 8) {
                Text("Recently Played")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text("Your most recently played music")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Divider()
                    .padding(.top, 8)
            }
            .padding(.top)
            
            // Songs view with recently played sort
            SongsView(initialSortOption: .recentlyPlayed, initialSortAscending: false)
                .environmentObject(musicLibrary)
        }
        .navigationTitle("Recently Played")
        .navigationBarTitleDisplayMode(.inline)
    }
}
