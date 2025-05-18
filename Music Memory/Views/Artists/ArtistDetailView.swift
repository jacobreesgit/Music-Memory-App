// Updated ArtistDetailView with RankedPlaylistsSection
// Music Memory

import SwiftUI
import MediaPlayer

struct ArtistDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let artist: ArtistData
    let rank: Int?
    
    // New state properties for background loading
    @State private var isLoadingDetails = true
    @State private var loadedAlbums: [AlbumData] = []
    @State private var loadedGenres: [GenreData] = []
    @State private var loadedPlaylists: [PlaylistData] = []
    @State private var genreRankings: [String: (rank: Int, total: Int)?] = [:]
    
    init(artist: ArtistData, rank: Int? = nil) {
        self.artist = artist
        self.rank = rank
    }
    
    var body: some View {
        MediaDetailView(
            item: artist,
            rank: rank,
            headerContent: { _ in headerSection },
            additionalContent: { _ in contentSections }
        )
        .onAppear {
            loadDetailsInBackground()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        // Sort Buttons Section - breaking up expressions for better type checking
        let albums = loadedAlbums
        let hasMultipleSongs = artist.songs.count > 1
        let hasMultipleAlbums = albums.count > 1
        
        return Group {
            if hasMultipleSongs || hasMultipleAlbums {
                VStack(spacing: 12) {
                    // Sort Albums Button - only show if there are multiple albums
                    if hasMultipleAlbums {
                        SortActionButton(
                            title: "Sort Albums",
                            items: albums,
                            source: .artist,
                            sourceID: artist.id,
                            sourceName: artist.name,
                            contentType: .albums,
                            artwork: artist.artwork
                        )
                    }
                    
                    // Sort Songs Button - only show if there are multiple songs
                    if hasMultipleSongs {
                        SortActionButton(
                            title: "Sort Songs",
                            items: artist.songs,
                            source: .artist,
                            sourceID: artist.id,
                            sourceName: artist.name,
                            contentType: .songs,
                            artwork: artist.artwork
                        )
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color(UIColor.systemGroupedBackground))
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
    }
    
    // MARK: - Content Sections
    
    private var contentSections: some View {
        Group {
            // Songs section
            SongsSection(songs: artist.songs)
            
            // Albums section
            if isLoadingDetails {
                loadingPlaceholder(title: "Albums")
            } else if !loadedAlbums.isEmpty {
                artistAlbumsSection(albums: loadedAlbums)
            }
            
            // Genres section
            if isLoadingDetails {
                loadingPlaceholder(title: "Genres")
            } else if !loadedGenres.isEmpty {
                artistGenresSection(genres: loadedGenres)
            }
            
            // Playlists section - Using RankedPlaylistsSection
            if !isLoadingDetails && !loadedPlaylists.isEmpty {
                RankedPlaylistsSection(
                    playlists: loadedPlaylists,
                    title: loadedPlaylists.count == 1 ? "Playlist" : "Playlists",
                    getRankData: { playlist in
                        getArtistRankInPlaylist(artist: artist, playlist: playlist)
                    }
                )
            }
        }
    }
    
    // MARK: - Loading Placeholder
    
    private func loadingPlaceholder(title: String) -> some View {
        Section(header: Text(title).padding(.leading, -15)) {
            HStack {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            }
            .padding(.vertical, 12)
            .listRowSeparator(.hidden)
        }
    }
    
    // MARK: - Album Section
    
    private func artistAlbumsSection(albums: [AlbumData]) -> some View {
        AlbumsSection(albums: albums)
    }
    
    // MARK: - Genres Section
    
    private func artistGenresSection(genres: [GenreData]) -> some View {
        Section(header: Text("Genres").padding(.leading, -15)) {
            ForEach(genres) { genre in
                NavigationLink(destination: GenreDetailView(genre: genre)) {
                    HStack(spacing: 10) {
                        // Show artist's rank within this genre using preloaded data
                        if let genreRank = genreRankings[genre.id],
                           let artistRankData = genreRank {
                            Text("\(artistRankData.rank)/\(artistRankData.total)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppStyles.accentColor)
                                .frame(width: 50, alignment: .leading)
                        } else {
                            // Placeholder while loading
                            Text("--/--")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.gray.opacity(0.5))
                                .frame(width: 50, alignment: .leading)
                        }
                        
                        LibraryRow.genre(genre)
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
    }
    
    // MARK: - Background Loading
    
    private func loadDetailsInBackground() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Find artist albums
            let artistAlbums = self.findArtistAlbums()
            
            // Find artist genres
            let artistGenres = self.findArtistGenres()
            
            // Find playlists containing artist's songs
            let containingPlaylists = self.findPlaylists()
            
            // Pre-load rankings for first few genres
            var genreRanks: [String: (rank: Int, total: Int)?] = [:]
            for genre in artistGenres.prefix(3) {
                genreRanks[genre.id] = self.getArtistRankInGenre(artist: self.artist, genre: genre)
            }
            
            // Update UI
            DispatchQueue.main.async {
                self.loadedAlbums = artistAlbums
                self.loadedGenres = artistGenres
                self.loadedPlaylists = containingPlaylists
                self.genreRankings = genreRanks
                self.isLoadingDetails = false
            }
            
            // Continue loading remaining genre rankings in background
            if artistGenres.count > 3 {
                for genre in artistGenres.dropFirst(3) {
                    let rank = self.getArtistRankInGenre(artist: self.artist, genre: genre)
                    DispatchQueue.main.async {
                        self.genreRankings[genre.id] = rank
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findArtistAlbums() -> [AlbumData] {
        return musicLibrary.albums.filter { $0.artist == artist.name }
            .sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findArtistGenres() -> [GenreData] {
        let genreNames = Set(artist.songs.compactMap { $0.genre })
        let genres = genreNames.compactMap { name -> GenreData? in
            musicLibrary.genres.first { $0.name == name }
        }
        return genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findPlaylists() -> [PlaylistData] {
        let artistSongIDs = Set(artist.songs.map { $0.persistentID })
        return musicLibrary.playlists.filter { playlist in
            playlist.songs.contains { artistSongIDs.contains($0.persistentID) }
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // MARK: - Contextual Ranking Methods
    
    // Get artist's rank within a genre
    private func getArtistRankInGenre(artist: ArtistData, genre: GenreData) -> (rank: Int, total: Int)? {
        // Get all artists in this genre
        let genreArtistNames = Set(genre.songs.compactMap { $0.artist })
        let genreArtists = genreArtistNames.compactMap { name -> ArtistData? in
            musicLibrary.artists.first { $0.name == name }
        }
        
        // Sort artists by play count
        let sortedArtists = genreArtists.sorted { $0.totalPlayCount > $1.totalPlayCount }
        
        // Find this artist's position
        if let index = sortedArtists.firstIndex(where: { $0.name == artist.name }) {
            return (rank: index + 1, total: sortedArtists.count)
        }
        
        return nil
    }
    
    // Get artist's rank within a playlist
    private func getArtistRankInPlaylist(artist: ArtistData, playlist: PlaylistData) -> (rank: Int, total: Int)? {
        // Get all artists in this playlist
        let playlistArtistNames = Set(playlist.songs.compactMap { $0.artist })
        
        // Create a dictionary to store total play counts per artist in this playlist
        var artistPlayCounts: [String: Int] = [:]
        
        // Calculate total play count per artist in this playlist
        for artistName in playlistArtistNames {
            let artistSongsInPlaylist = playlist.songs.filter { $0.artist == artistName }
            let totalPlays = artistSongsInPlaylist.reduce(0) { $0 + $1.playCount }
            artistPlayCounts[artistName] = totalPlays
        }
        
        // Sort artists by play count
        let sortedArtists = artistPlayCounts.sorted { $0.value > $1.value }
        
        // Find this artist's position
        if let index = sortedArtists.firstIndex(where: { $0.key == artist.name }) {
            return (rank: index + 1, total: playlistArtistNames.count)
        }
        
        return nil
    }
}
