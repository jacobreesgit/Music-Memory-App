//
//  GenreDetailView.swift
//  Music Memory
//
//  Created by Jacob Rees on 30/04/2025.
//

import SwiftUI
import MediaPlayer

struct GenreDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    let genre: GenreData
    let rank: Int?
    
    // State variables for expanded sections
    @State private var showAllSongs = false
    @State private var showAllArtists = false
    @State private var showAllAlbums = false
    @State private var showAllPlaylists = false
    
    // Initialize with an optional rank parameter
    init(genre: GenreData, rank: Int? = nil) {
        self.genre = genre
        self.rank = rank
    }
    
    // Helper function to format total duration
    private func totalDuration() -> String {
        let totalSeconds = genre.songs.reduce(0) { $0 + $1.playbackDuration }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return String(format: "%dh %dm", hours, minutes)
    }
    
    // Helper function to find artists in this genre
    private func genreArtists() -> [ArtistData] {
        // Get unique artist names in this genre
        let artistNames = Set(genre.songs.compactMap { $0.artist })
        
        // Find corresponding artist objects from the music library
        let artists = artistNames.compactMap { name -> ArtistData? in
            musicLibrary.artists.first { $0.name == name }
        }
        
        // Sort by play count
        return artists.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Helper function to find albums in this genre
    private func genreAlbums() -> [AlbumData] {
        // Get unique album titles in this genre
        let albumTitles = Set(genre.songs.compactMap { $0.albumTitle })
        
        // Find corresponding album objects from the music library
        let albums = albumTitles.compactMap { title -> AlbumData? in
            musicLibrary.albums.first { $0.title == title }
        }
        
        // Sort by play count
        return albums.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // Helper function to find playlists containing songs from this genre
    private func findPlaylists() -> [PlaylistData] {
        let genreSongIDs = Set(genre.songs.map { $0.persistentID })
        
        return musicLibrary.playlists.filter { playlist in
            // Check if playlist contains at least one song from this genre
            playlist.songs.contains { genreSongIDs.contains($0.persistentID) }
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    var body: some View {
        List {
            // Genre header section with optional rank
            Section(header: VStack(alignment: .center, spacing: 4) {
                if let rank = rank {
                    Text("Rank #\(rank)")
                        .font(.headline)
                        .foregroundColor(AppStyles.accentColor)
                        .padding(.bottom, 4)
                }
                
                DetailHeaderView(
                    title: genre.name,
                    subtitle: "",
                    plays: genre.totalPlayCount,
                    songCount: genre.songs.count,
                    artwork: genre.artwork,
                    isAlbum: false,
                    metadata: []
                )
            }) {
                // Empty section content for spacing
            }
            
            // Genre Statistics section
            Section(header: Text("Genre Statistics")
                .padding(.leading, -15)) {
                MetadataRow(icon: "music.mic", title: "Artists", value: "\(genre.artistCount)")
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "square.stack", title: "Albums", value: "\(genre.albumCount)")
                    .listRowSeparator(.hidden)
                MetadataRow(icon: "clock", title: "Total Time", value: totalDuration())
                    .listRowSeparator(.hidden)
                
                // Average play count per song
                MetadataRow(icon: "repeat", title: "Avg. Plays", value: "\(genre.averagePlayCount) per song")
                    .listRowSeparator(.hidden)
            }
            
            // Artists section with Show More/Less
            let artists = genreArtists()
            if !artists.isEmpty {
                Section(header: Text("Artists").padding(.leading, -15)) {
                    let displayedArtists = showAllArtists ? artists : Array(artists.prefix(5))
                    
                    ForEach(Array(displayedArtists.enumerated()), id: \.element.id) { index, artist in
                        NavigationLink(destination: ArtistDetailView(artist: artist)) {
                            HStack(spacing: 10) {
                                Text("#\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 30, alignment: .leading)
                                
                                ArtistRow(artist: artist)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    // Show More/Less button for artists
                    if artists.count > 5 {
                        Button(action: {
                            showAllArtists.toggle()
                        }) {
                            HStack {
                                Text(showAllArtists ? "Show Less" : "Show More")
                                    .font(.subheadline)
                                    .foregroundColor(AppStyles.accentColor)
                                
                                Image(systemName: showAllArtists ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(AppStyles.accentColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowSeparator(.hidden)
                    }
                }
            }
            
            // Albums section with Show More/Less
            let albums = genreAlbums()
            if !albums.isEmpty {
                Section(header: Text("Albums").padding(.leading, -15)) {
                    let displayedAlbums = showAllAlbums ? albums : Array(albums.prefix(5))
                    
                    ForEach(Array(displayedAlbums.enumerated()), id: \.element.id) { index, album in
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            HStack(spacing: 10) {
                                Text("#\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppStyles.accentColor)
                                    .frame(width: 30, alignment: .leading)
                                
                                AlbumRow(album: album)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    // Show More/Less button for albums
                    if albums.count > 5 {
                        Button(action: {
                            showAllAlbums.toggle()
                        }) {
                            HStack {
                                Text(showAllAlbums ? "Show Less" : "Show More")
                                    .font(.subheadline)
                                    .foregroundColor(AppStyles.accentColor)
                                
                                Image(systemName: showAllAlbums ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(AppStyles.accentColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowSeparator(.hidden)
                    }
                }
            }
            
            // Playlists section with Show More/Less
            let containingPlaylists = findPlaylists()
            if !containingPlaylists.isEmpty {
                Section(header: Text("In Playlists").padding(.leading, -15)) {
                    let displayedPlaylists = showAllPlaylists ? containingPlaylists : Array(containingPlaylists.prefix(5))
                    
                    ForEach(displayedPlaylists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                            PlaylistRow(playlist: playlist)
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    // Show More/Less button for playlists
                    if containingPlaylists.count > 5 {
                        Button(action: {
                            showAllPlaylists.toggle()
                        }) {
                            HStack {
                                Text(showAllPlaylists ? "Show Less" : "Show More")
                                    .font(.subheadline)
                                    .foregroundColor(AppStyles.accentColor)
                                
                                Image(systemName: showAllPlaylists ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(AppStyles.accentColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowSeparator(.hidden)
                    }
                }
            }
            
            // Songs section with ranking and Show More/Less
            Section(header: Text("Songs").padding(.leading, -15)) {
                let sortedSongs = genre.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }
                let displayedSongs = showAllSongs ? sortedSongs : Array(sortedSongs.prefix(5))
                
                ForEach(Array(displayedSongs.enumerated()), id: \.element.persistentID) { index, song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        HStack(spacing: 10) {
                            Text("#\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppStyles.accentColor)
                                .frame(width: 30, alignment: .leading)
                            
                            SongRow(song: song)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                
                // Show More/Less button for songs
                if sortedSongs.count > 5 {
                    Button(action: {
                        showAllSongs.toggle()
                    }) {
                        HStack {
                            Text(showAllSongs ? "Show Less" : "Show More")
                                .font(.subheadline)
                                .foregroundColor(AppStyles.accentColor)
                            
                            Image(systemName: showAllSongs ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(AppStyles.accentColor)
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowSeparator(.hidden)
                }
            }
        }
        .navigationTitle(genre.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
