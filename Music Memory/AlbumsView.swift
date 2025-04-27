import SwiftUI
import MediaPlayer

struct AlbumsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    
    var body: some View {
        NavigationView {
            if musicLibrary.isLoading {
                ProgressView("Loading albums...")
            } else if !musicLibrary.hasAccess {
                Text("Please grant music library access")
            } else {
                List(musicLibrary.albums) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        AlbumRow(album: album)
                    }
                }
                .navigationTitle("Albums by Plays")
            }
        }
    }
}

struct AlbumDetailView: View {
    let album: AlbumData
    
    var body: some View {
        List {
            Section(header: AlbumHeaderView(album: album)) {
                ForEach(album.songs.sorted { ($0.playCount ?? 0) > ($1.playCount ?? 0) }, id: \.persistentID) { song in
                    SongRow(song: song)
                }
            }
        }
        .navigationTitle(album.title)
    }
}