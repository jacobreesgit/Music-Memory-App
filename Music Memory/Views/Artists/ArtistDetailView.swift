// Updated ArtistDetailView with RankedPlaylistsSection
// Music Memory

import SwiftUI
import MediaPlayer

struct ArtistDetailView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @EnvironmentObject var sortSessionStore: SortSessionStore
    let artist: ArtistData
    let rank: Int?
    
    init(artist: ArtistData, rank: Int? = nil) {
        self.artist = artist
        self.rank = rank
    }
    
    var body: some View {
        MediaDetailView(
            item: artist,
            rank: rank,
            headerContent: { artist in
                // MARK: - Sort Buttons Section - NOW ABOVE STATISTICS
                let albums = findArtistAlbums()
                let hasMultipleSongs = artist.songs.count > 1
                let hasMultipleAlbums = albums.count > 1
                
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
            },
            additionalContent: { artist in
                Group {
                    // Songs section - MOVED TO TOP, already has internal rankings
                    SongsSection(songs: artist.songs)
                    
                    // Albums section - maintain internal rankings by play count
                    let artistAlbums = findArtistAlbums()
                    if !artistAlbums.isEmpty {
                        AlbumsSection(albums: artistAlbums)
                    }
                    
                    // Genres section - now with contextual external rankings
                    let genres = findArtistGenres()
                    if !genres.isEmpty {
                        Section(header: Text("Genres").padding(.leading, -15)) {
                            ForEach(genres) { genre in
                                NavigationLink(destination: GenreDetailView(genre: genre)) {
                                    HStack(spacing: 10) {
                                        // Show artist's rank within this genre with total count
                                        if let artistRankData = getArtistRankInGenre(artist: artist, genre: genre) {
                                            Text("#\(artistRankData.rank)/\(artistRankData.total)")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppStyles.accentColor)
                                                .frame(width: 50, alignment: .leading)
                                        }
                                        
                                        LibraryRow.genre(genre)
                                    }
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                    
                    // Playlists section - UPDATED to use RankedPlaylistsSection
                    let containingPlaylists = findPlaylists()
                    if !containingPlaylists.isEmpty {
                        RankedPlaylistsSection(
                            playlists: containingPlaylists,
                            getRankData: { playlist in
                                getArtistRankInPlaylist(artist: artist, playlist: playlist)
                            }
                        )
                    }
                }
            }
        )
    }
    
    // Helper methods (existing)
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
    
    // Structure to hold ranking data
    private struct RankData {
        let rank: Int
        let total: Int
    }
    
    // Get artist's rank within a genre
    private func getArtistRankInGenre(artist: ArtistData, genre: GenreData) -> RankData? {
        // Get all artists in this genre
        let genreArtistNames = Set(genre.songs.compactMap { $0.artist })
        let genreArtists = genreArtistNames.compactMap { name -> ArtistData? in
            musicLibrary.artists.first { $0.name == name }
        }
        
        // Sort artists by play count
        let sortedArtists = genreArtists.sorted { $0.totalPlayCount > $1.totalPlayCount }
        
        // Find this artist's position
        if let index = sortedArtists.firstIndex(where: { $0.name == artist.name }) {
            return RankData(rank: index + 1, total: sortedArtists.count)
        }
        
        return nil
    }
    
    // Get artist's rank within a playlist
    private func getArtistRankInPlaylist(artist: ArtistData, playlist: PlaylistData) -> RankData? {
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
            return RankData(rank: index + 1, total: playlistArtistNames.count)
        }
        
        return nil
    }
}
