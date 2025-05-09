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

    @State private var currentLeftIndex = 0
    @State private var currentRightIndex = 0
    @State private var totalBattles = 0
    @State private var remainingItems: [Any] = []
    @State private var sortedItems: [Any] = []
    @State private var isComparing = false
    @State private var showCancelAlert = false
    @State private var isCompleted = false

    // Helper properties for displaying items
    @State private var leftItemTitle = ""
    @State private var leftItemSubtitle = ""
    @State private var leftItemArtwork: MPMediaItemArtwork?
    @State private var rightItemTitle = ""
    @State private var rightItemSubtitle = ""
    @State private var rightItemArtwork: MPMediaItemArtwork?

    private func loadItems() {
        switch session.contentType {
        case .songs:
            loadSongs()
        case .albums:
            loadAlbums()
        case .artists:
            loadArtists()
        case .genres:
            loadGenres()
        case .playlists:
            loadPlaylists()
        }
    }
    
    private func loadSongs() {
        let persistentIDs = session.itemIDs.compactMap { UInt64($0) }
        let allSongs = musicLibrary.songs.filter { persistentIDs.contains($0.persistentID) }
        
        // If this is a continuing session, load the already sorted songs
        let sortedIDs = session.sortedIDs.compactMap { UInt64($0) }
        let sortedSongs = allSongs.filter { sortedIDs.contains($0.persistentID) }
        
        // Filter out already sorted songs for remaining pool
        let remaining = allSongs.filter { !sortedIDs.contains($0.persistentID) }
        
        remainingItems = remaining
        sortedItems = sortedSongs
    }
    
    private func loadAlbums() {
        let albumIDs = session.itemIDs
        let allAlbums = musicLibrary.albums.filter { albumIDs.contains($0.id) }
        
        // If this is a continuing session, load the already sorted albums
        let sortedIDs = session.sortedIDs
        let sortedAlbums = allAlbums.filter { sortedIDs.contains($0.id) }
        
        // Filter out already sorted albums for remaining pool
        let remaining = allAlbums.filter { !sortedIDs.contains($0.id) }
        
        remainingItems = remaining
        sortedItems = sortedAlbums
    }
    
    private func loadArtists() {
        let artistIDs = session.itemIDs
        let allArtists = musicLibrary.artists.filter { artistIDs.contains($0.id) }
        
        // If this is a continuing session, load the already sorted artists
        let sortedIDs = session.sortedIDs
        let sortedArtists = allArtists.filter { sortedIDs.contains($0.id) }
        
        // Filter out already sorted artists for remaining pool
        let remaining = allArtists.filter { !sortedIDs.contains($0.id) }
        
        remainingItems = remaining
        sortedItems = sortedArtists
    }
    
    private func loadGenres() {
        let genreIDs = session.itemIDs
        let allGenres = musicLibrary.genres.filter { genreIDs.contains($0.id) }
        
        // If this is a continuing session, load the already sorted genres
        let sortedIDs = session.sortedIDs
        let sortedGenres = allGenres.filter { sortedIDs.contains($0.id) }
        
        // Filter out already sorted genres for remaining pool
        let remaining = allGenres.filter { !sortedIDs.contains($0.id) }
        
        remainingItems = remaining
        sortedItems = sortedGenres
    }
    
    private func loadPlaylists() {
        let playlistIDs = session.itemIDs
        let allPlaylists = musicLibrary.playlists.filter { playlistIDs.contains($0.id) }
        
        // If this is a continuing session, load the already sorted playlists
        let sortedIDs = session.sortedIDs
        let sortedPlaylists = allPlaylists.filter { sortedIDs.contains($0.id) }
        
        // Filter out already sorted playlists for remaining pool
        let remaining = allPlaylists.filter { !sortedIDs.contains($0.id) }
        
        remainingItems = remaining
        sortedItems = sortedPlaylists
    }

    var body: some View {
        VStack {
            if isCompleted {
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
            VStack(alignment: .leading, spacing: 10) {
                Spacer().frame(height: 20)
                HStack {
                    Text("Battle #\(session.currentBattleIndex + 1)")
                        .font(.headline)
                        .foregroundColor(AppStyles.accentColor)

                    Spacer()

                    Text("\(Int((Double(session.sortedIDs.count) / Double(max(1, session.itemIDs.count))) * 100))% sorted")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(session.currentBattleIndex), total: Double(max(1, totalBattles)))
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(AppStyles.accentColor)
                    .padding(.top, 4)
            }
            .padding(.horizontal)

            Spacer(minLength: 0)

            if remainingItems.count >= 2 {
                HStack(alignment: .top, spacing: 30) {
                    ItemOptionView(
                        title: leftItemTitle,
                        subtitle: leftItemSubtitle,
                        artwork: leftItemArtwork,
                        contentType: session.contentType,
                        action: { selectItem(isLeft: true) }
                    )
                    
                    ItemOptionView(
                        title: rightItemTitle,
                        subtitle: rightItemSubtitle,
                        artwork: rightItemArtwork,
                        contentType: session.contentType,
                        action: { selectItem(isLeft: false) }
                    )
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text(remainingItems.isEmpty ? "Finalizing results..." : "Preparing items...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            }

            Spacer(minLength: 0)

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
        }
        .frame(maxHeight: .infinity)
        .disabled(isComparing)
    }
    
    // Start the sorting session
    private func startSorting() {
        // Load items based on content type
        loadItems()
        
        // Shuffle remaining items for initial comparisons if this is a new session
        if session.battleHistory.isEmpty {
            remainingItems.shuffle()
        }
        
        // Set initial indices or restore from saved battle state
        if remainingItems.count >= 2 {
            // If we have existing battle history, try to restore the current battle
            if !session.battleHistory.isEmpty, let lastBattle = session.battleHistory.last {
                // Try to find the indices of the last battle items in the remaining items
                if let leftIndex = findItemIndex(withID: lastBattle.leftItemID),
                   let rightIndex = findItemIndex(withID: lastBattle.rightItemID) {
                    currentLeftIndex = leftIndex
                    currentRightIndex = rightIndex
                } else {
                    // If we can't find the exact items, set up a new comparison
                    currentLeftIndex = 0
                    currentRightIndex = 1
                }
            } else {
                // Default for new session
                currentLeftIndex = 0
                currentRightIndex = 1
            }
            
            // Update the item details for the current comparison
            updateItemDetails()
        }
        
        // Calculate total expected battles (n log n for sorting)
        let n = Double(session.itemIDs.count)
        totalBattles = Int(n * log2(n))
    }
    
    // Update the details of the currently compared items for display
    private func updateItemDetails() {
        guard remainingItems.count >= 2 else { return }
        
        let leftItem = remainingItems[currentLeftIndex]
        let rightItem = remainingItems[currentRightIndex]
        
        switch session.contentType {
        case .songs:
            if let song = leftItem as? MPMediaItem {
                leftItemTitle = song.title ?? "Unknown"
                leftItemSubtitle = song.artist ?? "Unknown"
                leftItemArtwork = song.artwork
            }
            
            if let song = rightItem as? MPMediaItem {
                rightItemTitle = song.title ?? "Unknown"
                rightItemSubtitle = song.artist ?? "Unknown"
                rightItemArtwork = song.artwork
            }
            
        case .albums:
            if let album = leftItem as? AlbumData {
                leftItemTitle = album.title
                leftItemSubtitle = album.artist
                leftItemArtwork = album.artwork
            }
            
            if let album = rightItem as? AlbumData {
                rightItemTitle = album.title
                rightItemSubtitle = album.artist
                rightItemArtwork = album.artwork
            }
            
        case .artists:
            if let artist = leftItem as? ArtistData {
                leftItemTitle = artist.name
                leftItemSubtitle = "\(artist.songs.count) songs"
                leftItemArtwork = artist.artwork
            }
            
            if let artist = rightItem as? ArtistData {
                rightItemTitle = artist.name
                rightItemSubtitle = "\(artist.songs.count) songs"
                rightItemArtwork = artist.artwork
            }
            
        case .genres:
            if let genre = leftItem as? GenreData {
                leftItemTitle = genre.name
                leftItemSubtitle = "\(genre.songs.count) songs"
                leftItemArtwork = genre.artwork
            }
            
            if let genre = rightItem as? GenreData {
                rightItemTitle = genre.name
                rightItemSubtitle = "\(genre.songs.count) songs"
                rightItemArtwork = genre.artwork
            }
            
        case .playlists:
            if let playlist = leftItem as? PlaylistData {
                leftItemTitle = playlist.name
                leftItemSubtitle = "\(playlist.songs.count) songs"
                leftItemArtwork = playlist.artwork
            }
            
            if let playlist = rightItem as? PlaylistData {
                rightItemTitle = playlist.name
                rightItemSubtitle = "\(playlist.songs.count) songs"
                rightItemArtwork = playlist.artwork
            }
        }
    }
    
    // Get the ID for an item based on its type
    private func getItemID(_ item: Any) -> String {
        switch session.contentType {
        case .songs:
            if let song = item as? MPMediaItem {
                return song.persistentID.description
            }
        case .albums:
            if let album = item as? AlbumData {
                return album.id
            }
        case .artists:
            if let artist = item as? ArtistData {
                return artist.id
            }
        case .genres:
            if let genre = item as? GenreData {
                return genre.id
            }
        case .playlists:
            if let playlist = item as? PlaylistData {
                return playlist.id
            }
        }
        return ""
    }
    
    // Find the index of an item in remainingItems by its ID
    private func findItemIndex(withID id: String) -> Int? {
        for (index, item) in remainingItems.enumerated() {
            if getItemID(item) == id {
                return index
            }
        }
        return nil
    }
    
    // Handle item selection
    private func selectItem(isLeft: Bool) {
        guard remainingItems.count >= 2 else { return }
        
        isComparing = true
        
        // Record the current battle before making changes
        recordCurrentBattle()
        
        // Get the selected and unselected items
        let selectedIndex = isLeft ? currentLeftIndex : currentRightIndex
        
        let selected = remainingItems[selectedIndex]
        
        // Add to sorted list
        sortedItems.append(selected)
        
        // Update session data
        session.sortedIDs.append(getItemID(selected))
        session.currentBattleIndex += 1
        saveSession()
        
        // Remove the selected item from the pool
        remainingItems.remove(at: selectedIndex)
        
        // Adjust indices if needed
        if selectedIndex <= currentLeftIndex {
            currentLeftIndex = currentLeftIndex - 1
        }
        if selectedIndex <= currentRightIndex {
            currentRightIndex = currentRightIndex - 1
        }
        
        // Check if we're done
        if remainingItems.count < 2 {
            // Add any remaining item (should be at most 1)
            if let lastItem = remainingItems.first {
                sortedItems.append(lastItem)
                session.sortedIDs.append(getItemID(lastItem))
            }
            
            finishSorting()
        } else {
            // Set up next comparison
            setupNextComparison()
            updateItemDetails()
        }
        
        isComparing = false
    }
    
    // Handle "I Like Both" selection
    private func selectBoth() {
        guard remainingItems.count >= 2 else { return }
        
        isComparing = true
        
        // Record the current battle before making changes
        recordCurrentBattle()
        
        // Add both items to sorted list
        let left = remainingItems[currentLeftIndex]
        let right = remainingItems[currentRightIndex]
        
        // Order matters, so we'll remove from higher index first to avoid index shifting issues
        if currentLeftIndex > currentRightIndex {
            remainingItems.remove(at: currentLeftIndex)
            remainingItems.remove(at: currentRightIndex)
        } else {
            remainingItems.remove(at: currentRightIndex)
            remainingItems.remove(at: currentLeftIndex)
        }
        
        // Add both to sorted list - in the order they appeared
        sortedItems.append(left)
        sortedItems.append(right)
        
        // Update session data
        session.sortedIDs.append(getItemID(left))
        session.sortedIDs.append(getItemID(right))
        session.currentBattleIndex += 1
        saveSession()
        
        // Check if we're done
        if remainingItems.count < 2 {
            // Add any remaining item (should be at most 1)
            if let lastItem = remainingItems.first {
                sortedItems.append(lastItem)
                session.sortedIDs.append(getItemID(lastItem))
            }
            
            finishSorting()
        } else {
            // Set up next comparison
            setupNextComparison()
            updateItemDetails()
        }
        
        isComparing = false
    }
    
    // Skip the current comparison
    private func skipComparison() {
        guard remainingItems.count >= 2 else { return }
        
        // Record the current battle before making changes
        recordCurrentBattle()
        
        // Just set up a new comparison
        setupNextComparison()
        updateItemDetails()
        
        // Increment battle index
        session.currentBattleIndex += 1
        saveSession()
    }
    
    // Set up the next comparison
    private func setupNextComparison() {
        // Simple approach: just choose random indices
        var leftIndex = Int.random(in: 0..<remainingItems.count)
        var rightIndex = Int.random(in: 0..<remainingItems.count)
        
        // Make sure indices are different
        while leftIndex == rightIndex {
            rightIndex = Int.random(in: 0..<remainingItems.count)
        }
        
        currentLeftIndex = leftIndex
        currentRightIndex = rightIndex
    }
    
    // Record the current battle state for history
    private func recordCurrentBattle() {
        guard remainingItems.count >= 2 else { return }
        
        let leftItem = remainingItems[currentLeftIndex]
        let rightItem = remainingItems[currentRightIndex]
        
        // Add to history in the session model (for persistence)
        let battleRecord = SortSession.BattleRecord(
            leftItemID: getItemID(leftItem),
            rightItemID: getItemID(rightItem),
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
        
        // Check if we need to restore a sorted item
        if !sortedItems.isEmpty {
            // Remove the last one or two items from sorted items
            if sortedItems.count >= 2 && session.sortedIDs.count >= 2 {
                // Check if the last action was "I Like Both" by comparing the last two IDs
                let lastID = session.sortedIDs.last!
                let secondLastID = session.sortedIDs[session.sortedIDs.count - 2]
                
                // Check if the last two sorted items were from the same battle
                if session.sortedIDs.count - sortedItems.count <= 1 &&
                   (lastID == previousBattle.leftItemID ||
                    lastID == previousBattle.rightItemID) &&
                   (secondLastID == previousBattle.leftItemID ||
                    secondLastID == previousBattle.rightItemID) {
                    // This was likely an "I Like Both" action, remove both
                    let lastItem = sortedItems.removeLast()
                    let secondLastItem = sortedItems.removeLast()
                    
                    // Add them back to the remaining items
                    remainingItems.append(lastItem)
                    remainingItems.append(secondLastItem)
                    
                    // Remove from session IDs
                    session.sortedIDs.removeLast()
                    session.sortedIDs.removeLast()
                } else {
                    // Just remove the last one
                    let lastItem = sortedItems.removeLast()
                    remainingItems.append(lastItem)
                    session.sortedIDs.removeLast()
                }
            } else {
                // Just remove the last one
                let lastItem = sortedItems.removeLast()
                remainingItems.append(lastItem)
                session.sortedIDs.removeLast()
            }
        }
        
        // Find the indices of the previous battle items in the remaining items
        if let leftIndex = findItemIndex(withID: previousBattle.leftItemID),
           let rightIndex = findItemIndex(withID: previousBattle.rightItemID) {
            currentLeftIndex = leftIndex
            currentRightIndex = rightIndex
            updateItemDetails()
        } else {
            // If we can't find the exact items, just set up a new comparison
            setupNextComparison()
            updateItemDetails()
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

struct ItemOptionView: View {
    let title: String
    let subtitle: String
    let artwork: MPMediaItemArtwork?
    let contentType: SortSession.ContentType
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if let artwork = artwork {
                    Image(uiImage: artwork.image(at: CGSize(width: 140, height: 140)) ?? UIImage(systemName: iconForContentType())!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .cornerRadius(8)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .cornerRadius(8)
                        Image(systemName: iconForContentType())
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .frame(width: 140, height: 140)
                }
            }

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 140, alignment: .top)
            
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 140, alignment: .top)
        }
        .frame(width: 140, height: 220, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
    
    private func iconForContentType() -> String {
        switch contentType {
        case .songs:
            return "music.note"
        case .albums:
            return "square.stack"
        case .artists:
            return "music.mic"
        case .genres:
            return "music.note.list"
        case .playlists:
            return "list.bullet"
        }
    }
}
