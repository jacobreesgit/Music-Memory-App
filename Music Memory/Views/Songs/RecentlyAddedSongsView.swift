//
//  RecentlyAddedSongsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 11/05/2025.
//

import SwiftUI

struct RecentlyAddedSongsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(alignment: .leading, spacing: 8) {
                Text("Recently Added")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text("Your most recently added music")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Divider()
                    .padding(.top, 8)
            }
            .padding(.top)
            
            // Songs view with date added sort
            SongsView(initialSortOption: .dateAdded, initialSortAscending: false)
                .environmentObject(musicLibrary)
        }
        .navigationTitle("Recently Added")
        .navigationBarTitleDisplayMode(.inline)
    }
}
