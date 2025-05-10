//
//  ReplacementPlaylistView.swift
//  Music Memory
//
//  Created by Jacob Rees on 10/05/2025.
//

import SwiftUI
import MediaPlayer
import MusicKit

struct ReplacementPlaylistView: View {
    @ObservedObject var songVersionModel: SongVersionModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var playlistName = "Replacement Songs"
    @State private var playlistDescription = "Created by Music Memory to help consolidate play counts"
    @State private var isCreatingPlaylist = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Playlist metadata form
            Form {
                Section(header: Text("Playlist Information")) {
                    TextField("Playlist Name", text: $playlistName)
                    
                    TextField("Description", text: $playlistDescription)
                        .lineLimit(3)
                }
                
                Section(header: Text("Selected Replacements")) {
                    if songVersionModel.replacementMap.isEmpty {
                        Text("No songs selected for replacement")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(Array(songVersionModel.replacementMap.keys), id: \.persistentID) { librarySong in
                            if let replacement = songVersionModel.replacementMap[librarySong] {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Original song
                                    HStack(spacing: 4) {
                                        Text("📀 Original:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("\(librarySong.title ?? "Unknown") - \(librarySong.artist ?? "Unknown")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    // Replacement song
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.down")
                                            .font(.caption)
                                            .foregroundColor(AppStyles.accentColor)
                                        
                                        Text("\(replacement.title) - \(replacement.artistName)")
                                            .font(.caption.bold())
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                    }
                                    
                                    // Differences
                                    let differences = songVersionModel.getVersionDifferences(
                                        libraryItem: librarySong,
                                        catalogItem: replacement
                                    )
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(differences) { difference in
                                                VersionDifferenceTag(difference: difference)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding(.vertical, 4)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        songVersionModel.removeFromReplacementMap(librarySong)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        createPlaylist()
                    }) {
                        if isCreatingPlaylist {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.trailing, 10)
                                Text("Creating playlist...")
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Image(systemName: "music.note.list")
                                    .font(.headline)
                                Text("Create Playlist")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                    }
                    .disabled(songVersionModel.replacementMap.isEmpty || isCreatingPlaylist)
                    .listRowBackground(AppStyles.accentColor)
                    .foregroundColor(.white)
                }
                
                Section(footer: Text("This will create a playlist with all the replacement versions. You can then listen through this playlist to build up play counts in the newer versions.")) {
                    // Empty section for the footer
                }
            }
        }
        .alert("Playlist Created", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your replacement playlist has been created successfully.")
        }
        .alert("Error Creating Playlist", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createPlaylist() {
        guard !songVersionModel.replacementMap.isEmpty else { return }
        
        // Get the replacement songs
        let replacementSongs = Array(songVersionModel.replacementMap.values)
        
        isCreatingPlaylist = true
        
        Task {
            do {
                let success = await AppleMusicManager.shared.createPlaylist(
                    name: playlistName,
                    description: playlistDescription,
                    songs: replacementSongs
                )
                
                await MainActor.run {
                    isCreatingPlaylist = false
                    
                    if success {
                        showSuccessAlert = true
                    } else {
                        errorMessage = "Failed to create the playlist. Please try again."
                        showErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isCreatingPlaylist = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}
