//
//  SortSessionView.swift
//  Music Memory
//
//  Created by Jacob Rees on 07/05/2025.
//

import SwiftUI
import MediaPlayer

struct SortSessionView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    @State var session: SortSession
    
    // State for the sorting interface
    @State private var currentLeftIndex = 0
    @State private var currentRightIndex = 0
    @State private var totalBattles = 0
    @State private var remainingSongs = [MPMediaItem]()
    @State private var sortedSongs = [MPMediaItem]()
    @State private var isComparing = false
    @State private var showCancelAlert = false
    @State private var isCompleted = false
    
    // Load song data from persistent IDs
    private func loadSongs(from ids: [String]) -> [MPMediaItem] {
        let persistentIDs = ids.compactMap { UInt64($0) }
        return musicLibrary.songs.filter { persistentIDs.contains($0.persistentID) }
    }
    
    var body: some View {
        VStack {
            if isCompleted {
                // Redirect to results view when complete
                SortResultsView(session: session)
            } else {
                sortingView
            }
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showCancelAlert = true
                }) {
                    Text("Cancel")
                        .foregroundColor(AppStyles.accentColor)
                }
            }
        }
        .onAppear {
            startSorting()
        }
        .alert("Cancel Sorting?", isPresented: $showCancelAlert) {
            Button("Continue Sorting", role: .cancel) { }
            Button("Save Progress", role: .none) {
                saveSession()
                isCompleted = true
            }
            Button("Discard", role: .destructive) {
                if let index = sortSessionStore.sessions.firstIndex(where: { $0.id == session.id }) {
                    sortSessionStore.sessions.remove(at: index)
                    sortSessionStore.saveSessions()
                }
                isCompleted = true
            }
        } message: {
            Text("What would you like to do with your current sorting progress?")
        }
    }
    
    private var sortingView: some View {
        VStack(spacing: 0) {
            // Top header section with padding
            VStack(alignment: .leading, spacing: 10) {
                // Extra padding above battle header to match screenshot
                Spacer().frame(height: 20)
                
                // Battle header with percentage right-aligned
                HStack {
                    Text("Battle #\(session.currentBattleIndex + 1)")
                        .font(.headline)
                        .foregroundColor(AppStyles.accentColor)
                    
                    Spacer()
                    
                    Text("\(Int((Double(session.currentBattleIndex) / Double(max(1, totalBattles))) * 100))% sorted")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar
                ProgressView(value: Double(session.currentBattleIndex), total: Double(max(1, totalBattles)))
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(AppStyles.accentColor)
                    .padding(.top, 4)
            }
            .padding(.horizontal)
            
            // Main battle area with flexible spacing
            if remainingSongs.count >= 2 {
                Spacer(minLength: 80)
                
                // Song options in an HStack with equal alignment
                HStack(alignment: .top, spacing: 30) {
                    // Left song
                    SongOptionView(
                        song: remainingSongs[currentLeftIndex],
                        action: { selectSong(isLeft: true) }
                    )
                    
                    // Right song
                    SongOptionView(
                        song: remainingSongs[currentRightIndex],
                        action: { selectSong(isLeft: false) }
                    )
                }
                .padding(.horizontal)
                
                Spacer(minLength: 80)
                
                // Buttons section
                VStack(spacing: 12) {
                    Button(action: { selectBoth() }) {
                        Text("I Like Both")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(8)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { skipComparison() }) {
                        Text("No Opinion")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(8)
                            .foregroundColor(.primary)
                    }
                    
                    // Back button - always present but disabled as needed
                    Button(action: { goBackToPreviousBattle() }) {
                        HStack {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14))
                            Text("Go Back")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(8)
                        .foregroundColor(.red)
                    }
                    .disabled(session.currentBattleIndex < 1 || session.battleHistory.isEmpty)
                    .opacity(session.currentBattleIndex < 1 || session.battleHistory.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            } else {
                // Loading or completion state
                Spacer()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text(remainingSongs.isEmpty ? "Finalizing results..." : "Preparing songs...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .disabled(isComparing)
    }
    
    // Start the sorting session
    private func startSorting() {
        // Load songs from persistent IDs
        let allSongs = loadSongs(from: session.songIDs)
        
        // If this is a continuing session, load the already sorted songs
        let sortedIDs = session.sortedIDs.compactMap { UInt64($0) }
        sortedSongs = allSongs.filter { sortedIDs.contains($0.persistentID) }
        
        // Filter out already sorted songs for remaining pool
        remainingSongs = allSongs.filter { !sortedIDs.contains($0.persistentID) }
        
        // Shuffle remaining songs for initial comparisons if this is a new session
        if session.battleHistory.isEmpty {
            remainingSongs.shuffle()
        }
        
        // Set initial indices or restore from saved battle state
        if remainingSongs.count >= 2 {
            // If we have existing battle history, try to restore the current battle
            if !session.battleHistory.isEmpty, let lastBattle = session.battleHistory.last {
                // Try to find the indices of the last battle songs in the remaining songs
                if let leftIndex = findSongIndex(withID: lastBattle.leftSongID),
                   let rightIndex = findSongIndex(withID: lastBattle.rightSongID) {
                    currentLeftIndex = leftIndex
                    currentRightIndex = rightIndex
                } else {
                    // If we can't find the exact songs, set up a new comparison
                    currentLeftIndex = 0
                    currentRightIndex = 1
                }
            } else {
                // Default for new session
                currentLeftIndex = 0
                currentRightIndex = 1
            }
        }
        
        // Calculate total expected battles (n log n for sorting)
        let n = Double(allSongs.count)
        totalBattles = Int(n * log2(n))
    }
    
    // Find the index of a song in remainingSongs by its ID
    private func findSongIndex(withID idString: String) -> Int? {
        guard let id = UInt64(idString) else { return nil }
        return remainingSongs.firstIndex { $0.persistentID == id }
    }
    
    // Handle song selection
    private func selectSong(isLeft: Bool) {
        guard remainingSongs.count >= 2 else { return }
        
        isComparing = true
        
        // Record the current battle before making changes
        recordCurrentBattle()
        
        // Get the selected and unselected songs
        let selectedIndex = isLeft ? currentLeftIndex : currentRightIndex
        let unselectedIndex = isLeft ? currentRightIndex : currentLeftIndex
        
        let selected = remainingSongs[selectedIndex]
        
        // Add to sorted list
        sortedSongs.append(selected)
        
        // Update session data
        session.sortedIDs.append(selected.persistentID.description)
        session.currentBattleIndex += 1
        saveSession()
        
        // Remove the selected song from the pool
        remainingSongs.remove(at: selectedIndex)
        
        // Adjust indices if needed
        if selectedIndex <= currentLeftIndex {
            currentLeftIndex = currentLeftIndex - 1
        }
        if selectedIndex <= currentRightIndex {
            currentRightIndex = currentRightIndex - 1
        }
        
        // Check if we're done
        if remainingSongs.count < 2 {
            // Add any remaining song (should be at most 1)
            if let lastSong = remainingSongs.first {
                sortedSongs.append(lastSong)
                session.sortedIDs.append(lastSong.persistentID.description)
            }
            
            finishSorting()
        } else {
            // Set up next comparison
            setupNextComparison()
        }
        
        isComparing = false
    }
    
    // Handle "I Like Both" selection
    private func selectBoth() {
        guard remainingSongs.count >= 2 else { return }
        
        isComparing = true
        
        // Record the current battle before making changes
        recordCurrentBattle()
        
        // Add both songs to sorted list
        let left = remainingSongs[currentLeftIndex]
        let right = remainingSongs[currentRightIndex]
        
        // Order matters, so we'll remove from higher index first to avoid index shifting issues
        if currentLeftIndex > currentRightIndex {
            remainingSongs.remove(at: currentLeftIndex)
            remainingSongs.remove(at: currentRightIndex)
        } else {
            remainingSongs.remove(at: currentRightIndex)
            remainingSongs.remove(at: currentLeftIndex)
        }
        
        // Add both to sorted list - in the order they appeared
        sortedSongs.append(left)
        sortedSongs.append(right)
        
        // Update session data
        session.sortedIDs.append(left.persistentID.description)
        session.sortedIDs.append(right.persistentID.description)
        session.currentBattleIndex += 1
        saveSession()
        
        // Check if we're done
        if remainingSongs.count < 2 {
            // Add any remaining song (should be at most 1)
            if let lastSong = remainingSongs.first {
                sortedSongs.append(lastSong)
                session.sortedIDs.append(lastSong.persistentID.description)
            }
            
            finishSorting()
        } else {
            // Set up next comparison
            setupNextComparison()
        }
        
        isComparing = false
    }
    
    // Skip the current comparison
    private func skipComparison() {
        guard remainingSongs.count >= 2 else { return }
        
        // Record the current battle before making changes
        recordCurrentBattle()
        
        // Just set up a new comparison
        setupNextComparison()
        
        // Increment battle index
        session.currentBattleIndex += 1
        saveSession()
    }
    
    // Set up the next comparison
    private func setupNextComparison() {
        // Simple approach: just choose random indices
        var leftIndex = Int.random(in: 0..<remainingSongs.count)
        var rightIndex = Int.random(in: 0..<remainingSongs.count)
        
        // Make sure indices are different
        while leftIndex == rightIndex {
            rightIndex = Int.random(in: 0..<remainingSongs.count)
        }
        
        currentLeftIndex = leftIndex
        currentRightIndex = rightIndex
    }
    
    // Record the current battle state for history
    private func recordCurrentBattle() {
        guard remainingSongs.count >= 2 else { return }
        
        let leftSong = remainingSongs[currentLeftIndex]
        let rightSong = remainingSongs[currentRightIndex]
        
        // Add to history in the session model (for persistence)
        let battleRecord = SortSession.BattleRecord(
            leftSongID: leftSong.persistentID.description,
            rightSongID: rightSong.persistentID.description,
            battleIndex: session.currentBattleIndex
        )
        
        session.battleHistory.append(battleRecord)
    }
    
    // Go back to the previous battle
    private func goBackToPreviousBattle() {
        guard !session.battleHistory.isEmpty, session.currentBattleIndex > 0 else { return }
        
        // Get the previous battle
        let previousBattle = session.battleHistory.removeLast()
        
        // Decrement battle index
        session.currentBattleIndex -= 1
        
        // Check if we need to restore a sorted song
        if !sortedSongs.isEmpty {
            // Remove the last one or two songs from sorted songs
            if sortedSongs.count >= 2 && session.sortedIDs.count >= 2 {
                // Check if the last action was "I Like Both" by comparing the last two IDs
                let lastID = session.sortedIDs.last!
                let secondLastID = session.sortedIDs[session.sortedIDs.count - 2]
                
                // Check if the last two sorted songs were from the same battle
                if session.sortedIDs.count - sortedSongs.count <= 1 &&
                   (UInt64(lastID) == UInt64(previousBattle.leftSongID) ||
                    UInt64(lastID) == UInt64(previousBattle.rightSongID)) &&
                   (UInt64(secondLastID) == UInt64(previousBattle.leftSongID) ||
                    UInt64(secondLastID) == UInt64(previousBattle.rightSongID)) {
                    // This was likely an "I Like Both" action, remove both
                    let lastSong = sortedSongs.removeLast()
                    let secondLastSong = sortedSongs.removeLast()
                    
                    // Add them back to the remaining songs
                    remainingSongs.append(lastSong)
                    remainingSongs.append(secondLastSong)
                    
                    // Remove from session IDs
                    session.sortedIDs.removeLast()
                    session.sortedIDs.removeLast()
                } else {
                    // Just remove the last one
                    let lastSong = sortedSongs.removeLast()
                    remainingSongs.append(lastSong)
                    session.sortedIDs.removeLast()
                }
            } else {
                // Just remove the last one
                let lastSong = sortedSongs.removeLast()
                remainingSongs.append(lastSong)
                session.sortedIDs.removeLast()
            }
        }
        
        // Find the indices of the previous battle songs in the remaining songs
        if let leftSongID = UInt64(previousBattle.leftSongID),
           let rightSongID = UInt64(previousBattle.rightSongID) {
            if let leftIndex = remainingSongs.firstIndex(where: { $0.persistentID == leftSongID }),
               let rightIndex = remainingSongs.firstIndex(where: { $0.persistentID == rightSongID }) {
                currentLeftIndex = leftIndex
                currentRightIndex = rightIndex
            } else {
                // If we can't find the exact songs, just set up a new comparison
                setupNextComparison()
            }
        } else {
            // If we can't parse the IDs, just set up a new comparison
            setupNextComparison()
        }
        
        // Save the updated session
        saveSession()
    }
    
    // Complete the sorting process
    private func finishSorting() {
        // Mark session as complete
        session.isComplete = true
        saveSession()
        
        // Transition to completed state
        isCompleted = true
    }
    
    // Save session to the store
    private func saveSession() {
        sortSessionStore.updateSession(session)
    }
}

// MARK: - Song Option View

struct SongOptionView: View {
    let song: MPMediaItem
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            // Artwork container with fixed position
            ZStack {
                if let artwork = song.artwork {
                    Image(uiImage: artwork.image(at: CGSize(width: 140, height: 140)) ?? UIImage(systemName: "music.note")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .cornerRadius(8)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 140, height: 140)
                            .cornerRadius(8)
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Song title in separate container that allows expansion
            Text(song.title ?? "Unknown")
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 140)
        }
        .frame(width: 140)
        .contentShape(Rectangle()) // Make the whole area tappable
        .onTapGesture {
            action()
        }
    }
}
