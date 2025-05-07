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
            // Progress indicator
            VStack(spacing: 4) {
                ProgressView(value: Double(currentBattleIndex), total: Double(session.songIDs.count))
                    .progressViewStyle(.linear)
                    .tint(AppStyles.accentColor)
                
                HStack {
                    Text("Progress: \(Int((Double(currentBattleIndex) / Double(session.songIDs.count)) * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(currentBattleIndex)/\(session.songIDs.count) comparisons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Battle interface
            if remainingSongs.count >= 2 {
                VStack(spacing: 24) {
                    Text("Which song do you prefer?")
                        .font(AppStyles.headlineStyle)
                        .foregroundColor(AppStyles.accentColor)
                    
                    // Left song option
                    Button(action: { selectSong(isLeft: true) }) {
                        SongComparisonView(
                            song: remainingSongs[currentLeftIndex],
                            isHighlighted: false
                        )
                    }
                    .buttonStyle(SongSelectionButtonStyle())
                    
                    // VS indicator
                    Text("VS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, -8)
                    
                    // Right song option
                    Button(action: { selectSong(isLeft: false) }) {
                        SongComparisonView(
                            song: remainingSongs[currentRightIndex],
                            isHighlighted: false
                        )
                    }
                    .buttonStyle(SongSelectionButtonStyle())
                    
                    // Skip button
                    Button(action: { skipComparison() }) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("Skip this comparison")
                        }
                        .font(.subheadline)
                        .foregroundColor(AppStyles.accentColor.opacity(0.8))
                    }
                    .padding(.top, 8)
                }
                .padding()
                .disabled(isComparing)
                
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
        
        // Set initial battle index
        currentBattleIndex = session.sortedIDs.count
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
        
        // Increment battle index
        currentBattleIndex += 1
        
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
        
        // Just set up a new comparison
        setupNextComparison()
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

// Custom button style for song selection
struct SongSelectionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppStyles.cornerRadius)
                    .fill(Color.secondary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyles.cornerRadius)
                            .stroke(
                                configuration.isPressed ?
                                AppStyles.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// View for displaying a song in the comparison interface
struct SongComparisonView: View {
    let song: MPMediaItem
    let isHighlighted: Bool
    
    var body: some View {
        HStack(spacing: AppStyles.smallPadding) {
            // Artwork
            if let artwork = song.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 60, height: 60)) ?? UIImage(systemName: "music.note")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(AppStyles.cornerRadius)
            } else {
                Image(systemName: "music.note")
                    .frame(width: 60, height: 60)
                    .background(AppStyles.secondaryColor)
                    .cornerRadius(AppStyles.cornerRadius)
            }
            
            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title ?? "Unknown")
                    .font(AppStyles.bodyStyle)
                    .fontWeight(isHighlighted ? .bold : .regular)
                    .lineLimit(1)
                
                Text(song.artist ?? "Unknown")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(song.albumTitle ?? "Unknown")
                    .font(AppStyles.captionStyle)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play count
            Text("\(song.playCount ?? 0) plays")
                .font(AppStyles.captionStyle)
                .foregroundColor(isHighlighted ? AppStyles.accentColor : .secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
