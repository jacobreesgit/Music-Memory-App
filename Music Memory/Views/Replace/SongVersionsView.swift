//  SongVersionsView.swift
//  Music Memory

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
                // Original version header - now using VersionComparisonRow with special initializer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Version")
                        .font(.headline)
                        .foregroundColor(AppStyles.accentColor)
                        .padding(.horizontal)
                    
                    // Use VersionComparisonRow's special initializer for original songs
                    VersionComparisonRow(librarySong: librarySong, isOriginal: true)
                        .padding(.horizontal)
                }
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
