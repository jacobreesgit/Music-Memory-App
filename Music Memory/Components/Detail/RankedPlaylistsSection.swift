// RankedPlaylistsSection.swift
// Music Memory

import SwiftUI
import MediaPlayer

/// Reusable playlists section with contextual rank display and show more/less toggle
struct RankedPlaylistsSection: View {
    let playlists: [PlaylistData]
    let title: String
    let getRankData: (PlaylistData) -> (rank: Int, total: Int)?
    
    @State private var showAllPlaylists = false
    
    init(
        playlists: [PlaylistData],
        title: String = "In Playlists",
        getRankData: @escaping (PlaylistData) -> (rank: Int, total: Int)?
    ) {
        self.playlists = playlists
        self.title = title
        self.getRankData = getRankData
    }
    
    // New computed property to sort playlists by rank
    private var playlistsSortedByRank: [PlaylistData] {
        return playlists.sorted { playlist1, playlist2 in
            let rank1 = getRankData(playlist1)?.rank ?? Int.max
            let rank2 = getRankData(playlist2)?.rank ?? Int.max
            return rank1 < rank2
        }
    }
    
    var body: some View {
        Section(header: Text(title).padding(.leading, -15)) {
            // Use the sorted playlists instead of the original playlists
            let displayedPlaylists = showAllPlaylists ? playlistsSortedByRank : Array(playlistsSortedByRank.prefix(5))
            
            ForEach(displayedPlaylists) { playlist in
                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                    HStack(spacing: 10) {
                        // Show item's rank within this playlist with total count
                        if let rankData = getRankData(playlist) {
                            Text("\(rankData.rank)/\(rankData.total)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppStyles.accentColor)
                                .frame(width: 50, alignment: .leading)
                        }
                        
                        LibraryRow.playlist(playlist)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
            // Show More/Less button only if needed
            if playlists.count > 5 {
                ExpandCollapseButton(isExpanded: $showAllPlaylists)
            }
        }
    }
}
