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
        SongsView(initialSortOption: .dateAdded, initialSortAscending: false)
            .environmentObject(musicLibrary)
    }
}
