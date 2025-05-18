import SwiftUI
import MediaPlayer

struct AlbumDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let album: AlbumData
    let rank: Int?
    
    // New loading state properties
    @State private var isLoadingDetails = true
    @State private var genreRankings: [String: (rank: Int, total: Int)?] = [:]
    @State private var artistRanking: (rank: Int, total: Int)? = nil
    @State private var loadedArtist: ArtistData? = nil
    @State private var loadedGenres: [GenreData] = []
    @State private var loadedPlaylists: [PlaylistData] = []
    
    init(album: AlbumData, rank: Int? = nil) {
        self.album = album
        self.rank = rank
    }
    
    var body: some View {
        // Direct List implementation instead of complex MediaDetailView with closures
        List {
            // Header section
            Section {
                DetailHeaderView(
                    title: album.title,
                    subtitle: album.artist,
                    plays: album.totalPlayCount,
                    songCount: album.songs.count,
                    artwork: album.artwork,
                    isAlbum: true,
                    metadata: [],
                    rank: rank
                )
            }
            
            // Sort Songs button section
            sortSongsSection
            
            // Statistics section
            Section(header: Text("Statistics").padding(.leading, -15)) {
                ForEach(album.getMetadataItems()) { metadataItem in
                    MetadataRow(
                        icon: metadataItem.iconName,
                        title: metadataItem.label,
                        value: metadataItem.value
                    )
                    .listRowSeparator(.hidden)
                }
            }
            
            // Songs section
            SongsSection(songs: album.songs)
            
            // Artist section - using loaded artist data
            if isLoadingDetails {
                artistLoadingPlaceholder
            } else if let artist = loadedArtist {
                artistSection(artist: artist)
            }
            
            // Genres section - using loaded genre data
            if !isLoadingDetails && !loadedGenres.isEmpty {
                genresSection(genres: loadedGenres)
            }
            
            // Playlists section - using RankedPlaylistsSection with preloaded playlists
            if !isLoadingDetails && !loadedPlaylists.isEmpty {
                RankedPlaylistsSection(
                    playlists: loadedPlaylists,
                    title: loadedPlaylists.count == 1 ? "Playlist" : "Playlists",
                    getRankData: { playlist in
                        // Use background-computed data if available, otherwise compute on demand
                        getAlbumRankInPlaylist(playlist: playlist)
                    }
                )
            }
        }
        .listSectionSpacing(0)
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .withBottomSafeArea()
        .onAppear {
            loadDetailsInBackground()
        }
    }
    
    // MARK: - View Sections
    
    private var sortSongsSection: some View {
        Group {
            if album.songs.count > 1 {
                Section {
                    SortActionButton(
                        title: "Sort Songs",
                        items: album.songs,
                        source: .album,
                        sourceID: album.id,
                        sourceName: album.title,
                        contentType: .songs,
                        artwork: album.artwork
                    )
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color(UIColor.systemGroupedBackground))
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
    }
    
    private var artistLoadingPlaceholder: some View {
        Section(header: Text("Artist").padding(.leading, -15)) {
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
    
    private func artistSection(artist: ArtistData) -> some View {
        Section(header: Text("Artist").padding(.leading, -15)) {
            NavigationLink(destination: ArtistDetailView(artist: artist)) {
                HStack(spacing: 10) {
                    // Show album's rank within this artist's discography
                    if let albumRankData = artistRanking {
                        Text("\(albumRankData.rank)/\(albumRankData.total)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppStyles.accentColor)
                            .frame(width: 50, alignment: .leading)
                    }
                    
                    LibraryRow.artist(artist)
                }
            }
            .listRowSeparator(.hidden)
        }
    }
    
    private func genresSection(genres: [GenreData]) -> some View {
        Section(header: Text("Genres").padding(.leading, -15)) {
            ForEach(genres) { genre in
                NavigationLink(destination: GenreDetailView(genre: genre)) {
                    HStack(spacing: 10) {
                        // Show album's rank within this genre
                        if let genreRank = genreRankings[genre.id],
                           let albumRankData = genreRank {
                            Text("\(albumRankData.rank)/\(albumRankData.total)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppStyles.accentColor)
                                .frame(width: 50, alignment: .leading)
                        } else {
                            // Placeholder if rank not loaded yet
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
    
    // MARK: - Background Loading Functions
    
    private func loadDetailsInBackground() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            // Find artist
            let artist = findArtist(for: album)
            
            // Find genres
            let genres = findGenres(for: album)
            
            // Find playlists
            let playlists = findPlaylists(for: album)
            
            // Calculate artist ranking
            var artistRank: (rank: Int, total: Int)? = nil
            if let artist = artist {
                artistRank = getAlbumRankInArtist(artist: artist)
            }
            
            // Calculate genre rankings for the first few genres
            var genreRanks: [String: (rank: Int, total: Int)?] = [:]
            for genre in genres.prefix(3) {
                genreRanks[genre.id] = getAlbumRankInGenre(genre: genre)
            }
            
            // Update the UI
            DispatchQueue.main.async {
                self.loadedArtist = artist
                self.loadedGenres = genres
                self.loadedPlaylists = playlists
                self.artistRanking = artistRank
                self.genreRankings = genreRanks
                self.isLoadingDetails = false
            }
            
            // Continue loading the remaining genre rankings in the background
            if genres.count > 3 {
                for genre in genres.dropFirst(3) {
                    let rank = getAlbumRankInGenre(genre: genre)
                    DispatchQueue.main.async {
                        self.genreRankings[genre.id] = rank
                    }
                }
            }
        }
    }
    
    // MARK: - Data Helpers
    
    private func findArtist(for album: AlbumData) -> ArtistData? {
        return musicLibrary.artists.first { $0.name == album.artist }
    }
    
    private func findGenres(for album: AlbumData) -> [GenreData] {
        let genreNames = Set(album.songs.compactMap { $0.genre })
        let genres = genreNames.compactMap { name -> GenreData? in
            musicLibrary.genres.first { $0.name == name }
        }
        return genres.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    private func findPlaylists(for album: AlbumData) -> [PlaylistData] {
        let albumSongIDs = Set(album.songs.map { $0.persistentID })
        return musicLibrary.playlists.filter { playlist in
            playlist.songs.contains { albumSongIDs.contains($0.persistentID) }
        }.sorted { $0.totalPlayCount > $1.totalPlayCount }
    }
    
    // MARK: - Ranking Helpers
    
    // Structure to hold ranking data
    private struct RankData {
        let rank: Int
        let total: Int
    }
    
    // Get album's rank within an artist's discography
    private func getAlbumRankInArtist(artist: ArtistData) -> (rank: Int, total: Int)? {
        // Get all albums by this artist
        let artistAlbums = musicLibrary.albums.filter { $0.artist == artist.name }
        
        // Sort by play count
        let sortedAlbums = artistAlbums.sorted { $0.totalPlayCount > $1.totalPlayCount }
        
        // Find this album's position
        if let index = sortedAlbums.firstIndex(where: { $0.id == album.id }) {
            return (rank: index + 1, total: sortedAlbums.count)
        }
        
        return nil
    }
    
    // Get album's rank within a genre
    private func getAlbumRankInGenre(genre: GenreData) -> (rank: Int, total: Int)? {
        // Get all albums in this genre
        let genreAlbumTitles = Set(genre.songs.compactMap { $0.albumTitle })
        let genreAlbums = genreAlbumTitles.compactMap { title -> AlbumData? in
            musicLibrary.albums.first { $0.title == title }
        }
        
        // Calculate play counts per album from this genre's songs
        var albumPlayCounts: [String: Int] = [:]
        for genreAlbum in genreAlbums {
            let genreSongsInAlbum = genre.songs.filter { $0.albumTitle == genreAlbum.title }
            let totalPlays = genreSongsInAlbum.reduce(0) { $0 + $1.playCount }
            albumPlayCounts[genreAlbum.id] = totalPlays
        }
        
        // Sort albums by play count
        let sortedAlbumIDs = albumPlayCounts.sorted { $0.value > $1.value }.map { $0.key }
        
        // Find this album's position
        if let index = sortedAlbumIDs.firstIndex(of: album.id) {
            return (rank: index + 1, total: genreAlbums.count)
        }
        
        return nil
    }
    
    // Get album's rank within a playlist
    private func getAlbumRankInPlaylist(playlist: PlaylistData) -> (rank: Int, total: Int)? {
        // Get all albums in this playlist
        let playlistAlbumTitles = Set(playlist.songs.compactMap { $0.albumTitle })
        let playlistAlbums = playlistAlbumTitles.compactMap { title -> AlbumData? in
            musicLibrary.albums.first { $0.title == title }
        }
        
        // Calculate play counts per album from this playlist's songs
        var albumPlayCounts: [String: Int] = [:]
        for playlistAlbum in playlistAlbums {
            let playlistSongsInAlbum = playlist.songs.filter { $0.albumTitle == playlistAlbum.title }
            let totalPlays = playlistSongsInAlbum.reduce(0) { $0 + $1.playCount }
            albumPlayCounts[playlistAlbum.id] = totalPlays
        }
        
        // Sort albums by play count
        let sortedAlbumIDs = albumPlayCounts.sorted { $0.value > $1.value }.map { $0.key }
        
        // Find this album's position
        if let index = sortedAlbumIDs.firstIndex(of: album.id) {
            return (rank: index + 1, total: playlistAlbums.count)
        }
        
        return nil
    }
}
