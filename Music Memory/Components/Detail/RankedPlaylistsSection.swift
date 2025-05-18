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
                // Skeleton loader rows instead of spinner
                ForEach(0..<min(5, playlists.count), id: \.self) { index in
                    SkeletonPlaylistRow()
                }
                
                // Show More/Less button placeholder if needed
                if playlists.count > 5 {
                    SkeletonExpandButton()
                }
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
            // Process ALL playlists and collect their rankings
            var allRankings: [String: (rank: Int, total: Int)?] = [:]
            let timeout = DispatchTime.now() + .seconds(5) // Safety timeout
            
            // Process playlists in batches to avoid UI freezes if calculations are heavy
            for playlist in playlists {
                allRankings[playlist.id] = getRankData(playlist)
                
                // Check for timeout to prevent infinite loading
                if DispatchTime.now() > timeout {
                    break
                }
            }
            
            // Only once ALL rankings are loaded, update the UI
            DispatchQueue.main.async {
                self.loadedRankings = allRankings
                self.isLoadingRankings = false
            }
        }
    }
}

// Skeleton row for loading state
struct SkeletonPlaylistRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Rank placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 16)
                .frame(width: 50, alignment: .leading)
            
            // Artwork placeholder
            RoundedRectangle(cornerRadius: AppStyles.cornerRadius)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 14)
                    .frame(width: 120)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .frame(width: 80)
            }
            
            Spacer()
            
            // Play count
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 14)
                .frame(width: 70)
        }
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)
    }
}

// Skeleton expand/collapse button
struct SkeletonExpandButton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 16)
                .frame(width: 100)
            Spacer()
        }
        .padding(.vertical, 8)
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
        .listRowSeparator(.hidden)
    }
}
