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
    @State private var loadedRankings: [String: (rank: Int, total: Int)?] = [:]
    @State private var isLoadingRankings = true
    
    init(
        playlists: [PlaylistData],
        title: String = "In Playlists",
        getRankData: @escaping (PlaylistData) -> (rank: Int, total: Int)?
    ) {
        self.playlists = playlists
        self.title = title
        self.getRankData = getRankData
    }
    
    // New computed property to get sorted playlists using loaded rankings
    private var playlistsSortedByLoadedRanks: [PlaylistData] {
        return playlists.sorted { playlist1, playlist2 in
            let rank1 = loadedRankings[playlist1.id]??.rank ?? Int.max
            let rank2 = loadedRankings[playlist2.id]??.rank ?? Int.max
            return rank1 < rank2
        }
    }
    
    var body: some View {
        Section(header: Text(title).padding(.leading, -15)) {
            if isLoadingRankings {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading rankings...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .listRowSeparator(.hidden)
            } else {
                // Use the sorted playlists based on loaded rankings
                let displayedPlaylists = showAllPlaylists ?
                    playlistsSortedByLoadedRanks :
                    Array(playlistsSortedByLoadedRanks.prefix(5))
                
                ForEach(displayedPlaylists) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        HStack(spacing: 10) {
                            // Show item's rank within this playlist with total count if available
                            if let rankDataOptional = loadedRankings[playlist.id],
                               let rankData = rankDataOptional {
                                Text("\(rankData.rank)/\(rankData.total)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 50, alignment: .leading)
                            } else {
                                // Show placeholder if rank not yet calculated
                                Text("--/--")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.gray.opacity(0.5))
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
        .onAppear {
            loadRankingsInBackground()
        }
    }
    
    // New function to load rankings in background
    private func loadRankingsInBackground() {
        // Only load rankings if we haven't already
        guard isLoadingRankings else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Load first 3 rankings immediately for UI responsiveness
            let initialPlaylists = Array(playlists.prefix(3))
            var rankings: [String: (rank: Int, total: Int)?] = [:]
            
            for playlist in initialPlaylists {
                rankings[playlist.id] = getRankData(playlist)
            }
            
            // Update UI with initial rankings
            DispatchQueue.main.async {
                self.loadedRankings = rankings
                self.isLoadingRankings = false
            }
            
            // Continue loading remaining rankings in background
            if playlists.count > 3 {
                let remainingPlaylists = Array(playlists.dropFirst(3))
                var additionalRankings: [String: (rank: Int, total: Int)?] = [:]
                
                for playlist in remainingPlaylists {
                    additionalRankings[playlist.id] = getRankData(playlist)
                    
                    // Update in small batches for better responsiveness
                    if additionalRankings.count % 3 == 0 ||
                       playlist.id == remainingPlaylists.last?.id {
                        DispatchQueue.main.async {
                            self.loadedRankings.merge(additionalRankings) { current, _ in current }
                            additionalRankings = [:]
                        }
                    }
                }
            }
        }
    }
}
