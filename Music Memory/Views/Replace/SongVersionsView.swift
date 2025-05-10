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
    let includeRemixes: Bool
    
    @State private var catalogVersions: [Song] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedVersion: Song?
    
    var body: some View {
        VStack {
            // Original song header
            VStack(alignment: .leading, spacing: 8) {
                Text("Original Version")
                    .font(.headline)
                    .foregroundColor(AppStyles.accentColor)
                
                SongRow(song: librarySong)
                    .padding(.vertical, 4)
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
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Finding versions...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        Spacer()
                    }
                } else if let error = error {
                    Text("Error: \(error.localizedDescription)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                } else if catalogVersions.isEmpty {
                    Text("No alternative versions found")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    List {
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
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
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
            do {
                let versions = await AppleMusicManager.shared.findVersionsForSong(librarySong, includeRemixes: includeRemixes)
                
                await MainActor.run {
                    self.catalogVersions = versions
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
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
