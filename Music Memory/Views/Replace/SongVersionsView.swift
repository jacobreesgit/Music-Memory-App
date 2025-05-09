//
//  SongVersionsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 10/05/2025.
//

import SwiftUI
import MediaPlayer
import MusicKit

struct SongVersionsView: View {
    let librarySong: MPMediaItem
    @ObservedObject var songVersionModel: SongVersionModel
    
    @State private var catalogVersions: [Song] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedVersion: Song?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Original version header with enhanced display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Version")
                        .font(.headline)
                        .foregroundColor(AppStyles.accentColor)
                    
                    // Enhanced original song display with similar format to version comparison row
                    VStack(alignment: .leading, spacing: 8) {
                        // Song title
                        Text(librarySong.title ?? "Unknown")
                            .font(.headline)
                            .lineLimit(1)
                        
                        // Song details row
                        HStack(spacing: 12) {
                            // Artwork
                            if let artwork = librarySong.artwork {
                                Image(uiImage: artwork.image(at: CGSize(width: 60, height: 60)) ?? UIImage(systemName: "music.note")!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(AppStyles.cornerRadius)
                            } else {
                                Image(systemName: "music.note")
                                    .font(.system(size: 30))
                                    .frame(width: 60, height: 60)
                                    .background(AppStyles.secondaryColor)
                                    .cornerRadius(AppStyles.cornerRadius)
                            }
                            
                            // Song information
                            VStack(alignment: .leading, spacing: 2) {
                                // Artist
                                Text(librarySong.artist ?? "Unknown Artist")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                // Album
                                if let albumTitle = librarySong.albumTitle {
                                    Text(albumTitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                // Duration and year
                                let minutes = Int(librarySong.playbackDuration) / 60
                                let seconds = Int(librarySong.playbackDuration) % 60
                                let duration = String(format: "%d:%02d", minutes, seconds)
                                
                                let yearString = librarySong.releaseDate != nil ?
                                   DateFormatter().then { $0.dateFormat = "yyyy" }.string(from: librarySong.releaseDate!) :
                                   "Unknown"
                                
                                Text("\(duration) • \(yearString)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Explicit tag if applicable
                            if librarySong.isExplicitItem {
                                Text("E")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(4)
                                    .background(Color.red.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(AppStyles.secondaryColor.opacity(0.3))
                    .cornerRadius(AppStyles.cornerRadius)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Available versions section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Versions")
                        .font(.headline)
                        .foregroundColor(AppStyles.accentColor)
                        .padding(.horizontal)
                    
                    if isLoading {
                        // Loading spinner centered vertically
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                    Text("Finding versions...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                        .frame(height: 200) // Fixed height for proper vertical centering
                    } else if let error = error {
                        Text("Error: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    } else if catalogVersions.isEmpty {
                        // Empty state centered vertically
                        VStack {
                            Spacer()
                            Text("No alternative versions found")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                        .frame(height: 200) // Fixed height for proper vertical centering
                    } else {
                        // Results list
                        VStack(spacing: 12) {
                            ForEach(catalogVersions, id: \.id) { version in
                                VersionComparisonRow(
                                    librarySong: librarySong,
                                    catalogSong: version,
                                    isSelected: songVersionModel.replacementMap[librarySong]?.id == version.id,
                                    differences: songVersionModel.getVersionDifferences(
                                        libraryItem: librarySong,
                                        catalogItem: version
                                    )
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleSelection(for: version)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 4)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle(librarySong.title ?? "Song Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadVersions()
        }
    }
    
    private func loadVersions() {
        isLoading = true
        error = nil
        
        Task {
            // Simple search using the song title and artist
            let versions = await AppleMusicManager.shared.findVersionsForSong(librarySong)
            
            await MainActor.run {
                self.catalogVersions = versions
                self.isLoading = false
            }
        }
    }
    
    private func toggleSelection(for version: Song) {
        if songVersionModel.replacementMap[librarySong]?.id == version.id {
            // If already selected, deselect it
            songVersionModel.removeFromReplacementMap(librarySong)
        } else {
            // Otherwise, select it
            songVersionModel.addToReplacementMap(librarySong, replacement: version)
        }
    }
}

// Extension for DateFormatter to use functional programming style
extension DateFormatter {
    func then(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}
