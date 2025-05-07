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
    @State private var currentBattleIndex = 0
    @State private var battleNumber = 1
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
        VStack(spacing: 16) {
            // Battle heading and progress indicator
            VStack(spacing: 4) {
                Text("Battle #\(battleNumber)")
                    .font(.headline)
                    .foregroundColor(AppStyles.accentColor)
                
                Text("\(Int((Double(currentBattleIndex) / Double(session.songIDs.count)) * 100))% sorted")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ProgressView(value: Double(currentBattleIndex), total: Double(session.songIDs.count))
                    .progressViewStyle(.linear)
                    .tint(AppStyles.accentColor)
            }
            .padding(.horizontal)
            
            // Instructions
            Text("Pick what song you like better in each battle to get an accurate list of your favorite songs.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Battle interface
            if remainingSongs.count >= 2 {
                // Left song option
                Button(action: { selectSong(isLeft: true) }) {
                    SongComparisonView(
                        song: remainingSongs[currentLeftIndex],
                        isHighlighted: false
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(AppStyles.cornerRadius)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                
                // Middle options (I Like Both / No Opinion)
                HStack(spacing: 8) {
                    Button(action: { likeBoth() }) {
                        Text("I Like Both")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(AppStyles.cornerRadius)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { noOpinion() }) {
                        Text("No Opinion")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(AppStyles.cornerRadius)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                // Right song option
                Button(action: { selectSong(isLeft: false) }) {
                    SongComparisonView(
                        song: remainingSongs[currentRightIndex],
                        isHighlighted: false
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(AppStyles.cornerRadius)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                
            } else {
                // Loading or completion state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text(remainingSongs.isEmpty ? "Finalizing results..." : "Preparing songs...")
                        .font(AppStyles.bodyStyle)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
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
        
        // Shuffle remaining songs for initial comparisons
        remainingSongs.shuffle()
        
        // Set initial indices
        if remainingSongs.count >= 2 {
            currentLeftIndex = 0
            currentRightIndex = 1
        }
        
        // Set initial battle index and number
        currentBattleIndex = session.sortedIDs.count
        battleNumber = max(1, currentBattleIndex + 1)
    }
    
    // Handle song selection
    private func selectSong(isLeft: Bool) {
        guard remainingSongs.count >= 2 else { return }
        
        isComparing = true
        
        // Get the selected and unselected songs
        let selectedIndex = isLeft ? currentLeftIndex : currentRightIndex
        let unselectedIndex = isLeft ? currentRightIndex : currentLeftIndex
        
        let selected = remainingSongs[selectedIndex]
        
        // Add to sorted list
        sortedSongs.append(selected)
        
        // Update session data
        session.sortedIDs.append(selected.persistentID.description)
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
        
        // Increment battle index and number
        currentBattleIndex += 1
        battleNumber += 1
        
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
    private func likeBoth() {
        guard remainingSongs.count >= 2 else { return }
        
        isComparing = true
        
        // Add both songs to sorted list
        let song1 = remainingSongs[currentLeftIndex]
        let song2 = remainingSongs[currentRightIndex]
        
        // For a tie, we'll add both songs with the same ranking
        sortedSongs.append(song1)
        sortedSongs.append(song2)
        
        // Update session data
        session.sortedIDs.append(song1.persistentID.description)
        session.sortedIDs.append(song2.persistentID.description)
        session.ties.append((song1.persistentID.description, song2.persistentID.description))
        saveSession()
        
        // Remove both songs from the pool, careful of indices
        if currentLeftIndex < currentRightIndex {
            remainingSongs.remove(at: currentRightIndex)
            remainingSongs.remove(at: currentLeftIndex)
        } else {
            remainingSongs.remove(at: currentLeftIndex)
            remainingSongs.remove(at: currentRightIndex)
        }
        
        // Increment battle index and number
        currentBattleIndex += 2
        battleNumber += 1
        
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
    
    // Handle "No Opinion" selection
    private func noOpinion() {
        guard remainingSongs.count >= 2 else { return }
        
        isComparing = true
        
        // For no opinion, we'll add both to a different part of the list
        // or put them back in the pool for later comparison
        // For simplicity, we'll just skip and move to the next comparison for now
        
        // Record that we skipped this pair
        let song1 = remainingSongs[currentLeftIndex]
        let song2 = remainingSongs[currentRightIndex]
        session.skipped.append((song1.persistentID.description, song2.persistentID.description))
        saveSession()
        
        // Increment battle number but not battle index for skipped comparisons
        battleNumber += 1
        
        // Set up next comparison without removing songs
        setupNextComparison()
        
        isComparing = false
    }
    
    // Skip the current comparison
    private func skipComparison() {
        guard remainingSongs.count >= 2 else { return }
        
        // Record that we skipped this pair
        let song1 = remainingSongs[currentLeftIndex]
        let song2 = remainingSongs[currentRightIndex]
        session.skipped.append((song1.persistentID.description, song2.persistentID.description))
        saveSession()
        
        // Increment battle number but not battle index for skipped comparisons
        battleNumber += 1
        
        // Just set up a new comparison
        setupNextComparison()
    }
    
    // Set up the next comparison
    private func setupNextComparison() {
        guard remainingSongs.count >= 2 else { return }
        
        // Choose a pair that hasn't been skipped if possible
        var foundValidPair = false
        var attempts = 0
        let maxAttempts = 10 // Prevent infinite loop
        
        while !foundValidPair && attempts < maxAttempts {
            // Choose random indices
            var leftIndex = Int.random(in: 0..<remainingSongs.count)
            var rightIndex = Int.random(in: 0..<remainingSongs.count)
            
            // Make sure indices are different
            while leftIndex == rightIndex {
                rightIndex = Int.random(in: 0..<remainingSongs.count)
            }
            
            // Check if this pair has been skipped
            let song1ID = remainingSongs[leftIndex].persistentID.description
            let song2ID = remainingSongs[rightIndex].persistentID.description
            let pairSkipped = session.skipped.contains {
                ($0.0 == song1ID && $0.1 == song2ID) ||
                ($0.0 == song2ID && $0.1 == song1ID)
            }
            
            if !pairSkipped {
                foundValidPair = true
                currentLeftIndex = leftIndex
                currentRightIndex = rightIndex
                break
            }
            
            attempts += 1
        }
        
        // If we couldn't find a non-skipped pair, just use random indices
        if !foundValidPair {
            var leftIndex = Int.random(in: 0..<remainingSongs.count)
            var rightIndex = Int.random(in: 0..<remainingSongs.count)
            
            // Make sure indices are different
            while leftIndex == rightIndex {
                rightIndex = Int.random(in: 0..<remainingSongs.count)
            }
            
            currentLeftIndex = leftIndex
            currentRightIndex = rightIndex
        }
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

// View for displaying a song in the comparison interface
struct SongComparisonView: View {
    let song: MPMediaItem
    let isHighlighted: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            // Artwork
            if let artwork = song.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 100, height: 100)) ?? UIImage(systemName: "music.note")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .frame(width: 100, height: 100)
                    .background(AppStyles.secondaryColor)
                    .cornerRadius(AppStyles.cornerRadius)
            }
            
            // Song info
            Text(song.title ?? "Unknown")
                .font(.headline)
                .fontWeight(isHighlighted ? .bold : .regular)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(song.artist ?? "Unknown")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            // Album info (optional)
            if let album = song.albumTitle {
                Text(album)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// Extension to SortSession to support ties and skipped comparisons
extension SortSession {
    // New properties to be added to the SortSession.swift file
    var ties: [(String, String)] = []
    var skipped: [(String, String)] = []
    
    // Reset encoding/decoding to include these new properties
    enum CodingKeys: String, CodingKey {
        case id, title, source, sourceID, sourceName, date, songIDs, sortedIDs, isComplete, artworkData, ties, skipped
    }
}
