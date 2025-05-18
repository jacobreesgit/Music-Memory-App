//  DetailViewSections.swift
//  Music Memory

import SwiftUI
import MediaPlayer

/// Reusable Songs section with show more/less toggle
struct SongsSection: View {
    let songs: [MPMediaItem]
    let title: String
    
    @State private var showAllSongs = false
    
    init(songs: [MPMediaItem], title: String = "Songs") {
        self.songs = songs
        self.title = title
    }
    
    var body: some View {
        Section(header: Text(title).padding(.leading, -15)) {
            let sortedSongs = songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }
            let displayedSongs = showAllSongs ? sortedSongs : Array(sortedSongs.prefix(5))
            
            ForEach(Array(displayedSongs.enumerated()), id: \.element.persistentID) { index, song in
                NavigationLink(destination: SongDetailView(song: song)) {
                    HStack(spacing: 10) {
                        // Only show rank number if there's more than one song
                        if displayedSongs.count > 1 {
                            Text("#\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppStyles.accentColor)
                                .frame(width: 30, alignment: .leading)
                        }
                        
                        LibraryRow.song(song)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
            // Show More/Less button only if needed
            if sortedSongs.count > 5 {
                ExpandCollapseButton(isExpanded: $showAllSongs)
            }
        }
    }
}

/// Reusable albums section
struct AlbumsSection: View {
    let albums: [AlbumData]
    let title: String
    
    @State private var showAllAlbums = false
    
    init(albums: [AlbumData], title: String = "Albums") {
        self.albums = albums
        self.title = title
    }
    
    var body: some View {
        Section(header: Text(title).padding(.leading, -15)) {
            let displayedAlbums = showAllAlbums ? albums : Array(albums.prefix(5))
            
            ForEach(Array(displayedAlbums.enumerated()), id: \.element.id) { index, album in
                NavigationLink(destination: AlbumDetailView(album: album)) {
                    HStack(spacing: 10) {
                        if displayedAlbums.count > 1 {
                            Text("#\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppStyles.accentColor)
                                .frame(width: 30, alignment: .leading)
                        }
                        
                        LibraryRow.album(album)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
            if albums.count > 5 {
                ExpandCollapseButton(isExpanded: $showAllAlbums)
            }
        }
    }
}

/// Reusable artists section
struct ArtistsSection: View {
    let artists: [ArtistData]
    let title: String
    
    @State private var showAllArtists = false
    
    init(artists: [ArtistData], title: String = "Artists") {
        self.artists = artists
        self.title = title
    }
    
    var body: some View {
        Section(header: Text(title).padding(.leading, -15)) {
            let displayedArtists = showAllArtists ? artists : Array(artists.prefix(5))
            
            ForEach(Array(displayedArtists.enumerated()), id: \.element.id) { index, artist in
                NavigationLink(destination: ArtistDetailView(artist: artist)) {
                    HStack(spacing: 10) {
                        if displayedArtists.count > 1 {
                            Text("#\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppStyles.accentColor)
                                .frame(width: 30, alignment: .leading)
                        }
                        
                        LibraryRow.artist(artist)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
            if artists.count > 5 {
                ExpandCollapseButton(isExpanded: $showAllArtists)
            }
        }
    }
}

/// Reusable genres section
struct GenresSection: View {
    let genres: [GenreData]
    let title: String
    
    @State private var showAllGenres = false
    
    init(genres: [GenreData], title: String = "Genres") {
        self.genres = genres
        self.title = title
    }
    
    var body: some View {
        Section(header: Text(title).padding(.leading, -15)) {
            let displayedGenres = showAllGenres ? genres : Array(genres.prefix(5))
            
            ForEach(Array(displayedGenres.enumerated()), id: \.element.id) { index, genre in
                NavigationLink(destination: GenreDetailView(genre: genre)) {
                    HStack(spacing: 10) {
                        if displayedGenres.count > 1 {
                            Text("#\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppStyles.accentColor)
                                .frame(width: 30, alignment: .leading)
                        }
                        
                        LibraryRow.genre(genre)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
            if genres.count > 5 {
                ExpandCollapseButton(isExpanded: $showAllGenres)
            }
        }
    }
}

/// Reusable playlists section
struct PlaylistsSection: View {
    let playlists: [PlaylistData]
    let title: String
    
    @State private var showAllPlaylists = false
    
    init(playlists: [PlaylistData], title: String = "Playlists") {
        self.playlists = playlists
        self.title = title
    }
    
    var body: some View {
        Section(header: Text(title).padding(.leading, -15)) {
            let displayedPlaylists = showAllPlaylists ? playlists : Array(playlists.prefix(5))
            
            ForEach(Array(displayedPlaylists.enumerated()), id: \.element.id) { index, playlist in
                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                    HStack(spacing: 10) {
                        if displayedPlaylists.count > 1 {
                            Text("#\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppStyles.accentColor)
                                .frame(width: 30, alignment: .leading)
                        }
                        
                        LibraryRow.playlist(playlist)
                    }
                }
                .listRowSeparator(.hidden)
            }
            
            if playlists.count > 5 {
                ExpandCollapseButton(isExpanded: $showAllPlaylists)
            }
        }
    }
}

/// Reusable expand/collapse button for section lists
struct ExpandCollapseButton: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button(action: {
            isExpanded.toggle()
        }) {
            HStack {
                Text(isExpanded ? "Show Less" : "Show More")
                    .font(.subheadline)
                    .foregroundColor(AppStyles.accentColor)
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
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
