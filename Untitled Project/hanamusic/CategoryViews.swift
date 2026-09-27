import SwiftUI

#if os(iOS)
import MediaPlayer

// MARK: - 1. 按艺术家分类视图（带 A-Z 及假名索引）
struct ArtistsListView: View {
    @ObservedObject var musicManager: MusicManager
    @State private var searchText: String = ""

    var filteredArtists: [MPMediaItemCollection] {
        if searchText.isEmpty {
            return musicManager.artists
        }
        return musicManager.artists.filter { collection in
            let name = collection.representativeItem?.artist ?? ""
            return name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedArtists: [(key: String, items: [MPMediaItemCollection])] {
        SectionIndexHelper.groupItems(filteredArtists) { collection in
            collection.representativeItem?.artist ?? L10n.unknownArtist
        }
    }

    var body: some View {
        Group {
            if filteredArtists.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L10n.noArtistsFound)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ZStack(alignment: .trailing) {
                        List {
                            ForEach(groupedArtists, id: \.key) { section in
                                Section(header: Text(section.key).id(section.key).font(.subheadline).bold()) {
                                    ForEach(section.items, id: \.persistentID) { collection in
                                        let artistName = collection.representativeItem?.artist ?? L10n.unknownArtist
                                        NavigationLink(destination: CollectionDetailView(
                                            title: artistName,
                                            subtitle: L10n.songCount(collection.count),
                                            collection: collection,
                                            musicManager: musicManager
                                        )) {
                                            HStack(spacing: 14) {
                                                if let artwork = collection.representativeItem?.artwork,
                                                   let image = artwork.image(at: CGSize(width: 48, height: 48)) {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 48, height: 48)
                                                        .clipShape(Circle())
                                                } else {
                                                    ZStack {
                                                        Color(UIColor.systemGray5)
                                                        Image(systemName: "person.fill")
                                                            .foregroundColor(.gray)
                                                    }
                                                    .frame(width: 48, height: 48)
                                                    .clipShape(Circle())
                                                }

                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(artistName)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .lineLimit(1)
                                                    Text(L10n.songCount(collection.count))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 3)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 110)
                        }

                        SectionIndexBar(sections: SectionIndexHelper.indexTitles) { key in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(key, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: L10n.searchArtists)
        .navigationTitle(L10n.artists)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 2. 按流派分类视图（带 A-Z 及假名索引）
struct GenresListView: View {
    @ObservedObject var musicManager: MusicManager
    @State private var searchText: String = ""

    var filteredGenres: [MPMediaItemCollection] {
        if searchText.isEmpty {
            return musicManager.genres
        }
        return musicManager.genres.filter { collection in
            let name = collection.representativeItem?.genre ?? ""
            return name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedGenres: [(key: String, items: [MPMediaItemCollection])] {
        SectionIndexHelper.groupItems(filteredGenres) { collection in
            collection.representativeItem?.genre ?? L10n.unknownGenre
        }
    }

    var body: some View {
        Group {
            if filteredGenres.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "guitars")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L10n.noGenresFound)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ZStack(alignment: .trailing) {
                        List {
                            ForEach(groupedGenres, id: \.key) { section in
                                Section(header: Text(section.key).id(section.key).font(.subheadline).bold()) {
                                    ForEach(section.items, id: \.persistentID) { collection in
                                        let genreName = collection.representativeItem?.genre ?? L10n.unknownGenre
                                        NavigationLink(destination: CollectionDetailView(
                                            title: genreName,
                                            subtitle: L10n.songCount(collection.count),
                                            collection: collection,
                                            musicManager: musicManager
                                        )) {
                                            HStack(spacing: 14) {
                                                if let artwork = collection.representativeItem?.artwork,
                                                   let image = artwork.image(at: CGSize(width: 48, height: 48)) {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 48, height: 48)
                                                        .cornerRadius(8)
                                                } else {
                                                    ZStack {
                                                        Color.purple.opacity(0.15)
                                                        Image(systemName: "music.quarternote.3")
                                                            .foregroundColor(.purple)
                                                    }
                                                    .frame(width: 48, height: 48)
                                                    .cornerRadius(8)
                                                }

                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(genreName)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .lineLimit(1)
                                                    Text(L10n.songCount(collection.count))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 3)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 110)
                        }

                        SectionIndexBar(sections: SectionIndexHelper.indexTitles) { key in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(key, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: L10n.searchGenres)
        .navigationTitle(L10n.genres)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 3. 专辑全览列表视图（带 A-Z 及假名索引）
struct AlbumsFullListView: View {
    @ObservedObject var musicManager: MusicManager
    @State private var searchText: String = ""

    var filteredAlbums: [MPMediaItemCollection] {
        if searchText.isEmpty {
            return musicManager.albums
        }
        return musicManager.albums.filter { album in
            let title = album.representativeItem?.albumTitle ?? ""
            let artist = album.representativeItem?.artist ?? ""
            return title.localizedCaseInsensitiveContains(searchText) ||
                   artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedAlbums: [(key: String, items: [MPMediaItemCollection])] {
        SectionIndexHelper.groupItems(filteredAlbums) { album in
            album.representativeItem?.albumTitle ?? L10n.unknownAlbum
        }
    }

    var body: some View {
        Group {
            if filteredAlbums.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "square.stack.3d.down.right")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L10n.noAlbumsFound)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ZStack(alignment: .trailing) {
                        List {
                            ForEach(groupedAlbums, id: \.key) { section in
                                Section(header: Text(section.key).id(section.key).font(.subheadline).bold()) {
                                    ForEach(section.items, id: \.persistentID) { album in
                                        let title = album.representativeItem?.albumTitle ?? L10n.unknownAlbum
                                        let artist = album.representativeItem?.artist ?? L10n.unknownArtist
                                        NavigationLink(destination: CollectionDetailView(
                                            title: title,
                                            subtitle: artist,
                                            collection: album,
                                            musicManager: musicManager
                                        )) {
                                            CollectionRowView(
                                                title: title,
                                                subtitle: "\(artist) · " + L10n.songCount(album.count),
                                                artwork: album.representativeItem?.artwork,
                                                fallbackIcon: "opticaldisc"
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 110)
                        }

                        SectionIndexBar(sections: SectionIndexHelper.indexTitles) { key in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(key, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: L10n.searchAlbums)
        .navigationTitle(L10n.albums)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 4. 歌单全览列表视图（带 A-Z 及假名索引与更多菜单）
struct PlaylistsFullListView: View {
    @ObservedObject var musicManager: MusicManager
    @State private var searchText: String = ""

    var filteredPlaylists: [MPMediaItemCollection] {
        if searchText.isEmpty {
            return musicManager.playlists
        }
        return musicManager.playlists.filter { playlist in
            let name = playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? ""
            return name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedPlaylists: [(key: String, items: [MPMediaItemCollection])] {
        SectionIndexHelper.groupItems(filteredPlaylists) { playlist in
            playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? L10n.untitledPlaylist
        }
    }

    var body: some View {
        Group {
            if filteredPlaylists.isEmpty && musicManager.customPlaylists.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L10n.noPlaylistsFound)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ZStack(alignment: .trailing) {
                        List {
                            if !musicManager.customPlaylists.isEmpty {
                                Section(header: Text(L10n.customPlaylists).font(.subheadline).bold()) {
                                    ForEach(musicManager.customPlaylists) { custom in
                                        HStack(spacing: 14) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(hex: custom.coverColorHex))
                                                    .frame(width: 48, height: 48)
                                                Image(systemName: custom.coverSymbol)
                                                    .font(.system(size: 22))
                                                    .foregroundColor(.white)
                                            }

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(custom.name)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.primary)
                                                Text(L10n.songCount(custom.songPersistentIDs.count))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            playlistContextMenu(name: custom.name, customID: custom.id)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }

                            ForEach(groupedPlaylists, id: \.key) { section in
                                Section(header: Text(section.key).id(section.key).font(.subheadline).bold()) {
                                    ForEach(section.items, id: \.persistentID) { playlist in
                                        let name = playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? L10n.untitledPlaylist
                                        HStack {
                                            NavigationLink(destination: CollectionDetailView(
                                                title: name,
                                                subtitle: L10n.songCount(playlist.count),
                                                collection: playlist,
                                                musicManager: musicManager
                                            )) {
                                                CollectionRowView(
                                                    title: name,
                                                    subtitle: L10n.songCount(playlist.count),
                                                    artwork: playlist.representativeItem?.artwork,
                                                    fallbackIcon: "music.note.list"
                                                )
                                            }

                                            playlistContextMenu(name: name, collection: playlist)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 110)
                        }

                        SectionIndexBar(sections: SectionIndexHelper.indexTitles) { key in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(key, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: L10n.searchPlaylists)
        .navigationTitle(L10n.tabPlaylists)
        .navigationBarTitleDisplayMode(.inline)
    }

    // 实例图片2完整 8 项功能菜单组件（多语言跟随系统）
    @ViewBuilder
    private func playlistContextMenu(name: String, collection: MPMediaItemCollection? = nil, customID: UUID? = nil) -> some View {
        Menu {
            // 1. すべて再生
            Button(action: {
                if let col = collection {
                    musicManager.playAll(collection: col, shuffle: false)
                }
            }) {
                Label(L10n.playAll, systemImage: "play.circle")
            }

            // 2. 画像を編集
            Button(action: {}) {
                Label(L10n.editImage, systemImage: "photo")
            }

            // 3. カバーを生成
            Button(action: {
                if let id = customID {
                    musicManager.generateCover(for: id)
                }
            }) {
                Label(L10n.generateCover, systemImage: "sparkles")
            }

            // 4. 曲を追加
            Button(action: {}) {
                Label(L10n.addSongs, systemImage: "plus")
            }

            // 5. 名称変更
            Button(action: {}) {
                Label(L10n.rename, systemImage: "pencil")
            }

            // 6. プレイリストに追加する
            Button(action: {}) {
                Label(L10n.addToPlaylist, systemImage: "text.badge.plus")
            }

            // 7. ウォッチへ転送
            Button(action: {}) {
                Label(L10n.transferToWatch, systemImage: "applewatch")
            }

            Divider()

            // 8. プレイリストを削除
            Button(role: .destructive, action: {
                if let id = customID {
                    musicManager.deleteCustomPlaylist(id: id)
                }
            }) {
                Label(L10n.deletePlaylist, systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
    }
}

// MARK: - 5. 歌曲全览列表视图（带 A-Z 及假名索引）
struct SongsFullListView: View {
    @ObservedObject var musicManager: MusicManager
    @State private var searchText: String = ""

    var filteredSongs: [MPMediaItem] {
        let baseSongs: [MPMediaItem]
        switch musicManager.songSortOption {
        case .title:
            baseSongs = musicManager.songs.sorted { ($0.title ?? "") < ($1.title ?? "") }
        case .artist:
            baseSongs = musicManager.songs.sorted { ($0.artist ?? "") < ($1.artist ?? "") }
        case .dateAdded:
            baseSongs = musicManager.songs.sorted {
                let d1 = $0.value(forProperty: MPMediaItemPropertyDateAdded) as? Date ?? Date.distantPast
                let d2 = $1.value(forProperty: MPMediaItemPropertyDateAdded) as? Date ?? Date.distantPast
                return d1 > d2
            }
        }

        if searchText.isEmpty {
            return baseSongs
        }
        return baseSongs.filter { song in
            (song.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (song.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var groupedSongs: [(key: String, items: [MPMediaItem])] {
        SectionIndexHelper.groupItems(filteredSongs) { song in
            song.title ?? L10n.unknownTrack
        }
    }

    var body: some View {
        Group {
            if filteredSongs.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "music.note")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L10n.noSongsFound)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ZStack(alignment: .trailing) {
                        List {
                            ForEach(groupedSongs, id: \.key) { section in
                                Section(header: Text(section.key).id(section.key).font(.subheadline).bold()) {
                                    ForEach(section.items, id: \.persistentID) { song in
                                        HStack(spacing: 12) {
                                            if let artwork = song.artwork,
                                               let image = artwork.image(at: CGSize(width: 46, height: 46)) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 46, height: 46)
                                                    .cornerRadius(6)
                                            } else {
                                                ZStack {
                                                    Color(UIColor.systemGray5)
                                                    Image(systemName: "music.note")
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(width: 46, height: 46)
                                                .cornerRadius(6)
                                            }

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(song.title ?? L10n.unknownTrack)
                                                    .font(.system(size: 16, weight: .regular))
                                                    .foregroundColor(musicManager.currentSong?.persistentID == song.persistentID ? .red : .primary)
                                                    .lineLimit(1)

                                                Text(song.artist ?? L10n.unknownArtist)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }

                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            musicManager.play(song: song, from: filteredSongs)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 110)
                        }

                        SectionIndexBar(sections: SectionIndexHelper.indexTitles) { key in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(key, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: L10n.searchSongs)
        .navigationTitle(L10n.tabSongs)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 颜色 Hex 扩展
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            let r = Double((hexNumber & 0xff0000) >> 16) / 255
            let g = Double((hexNumber & 0x00ff00) >> 8) / 255
            let b = Double(hexNumber & 0x0000ff) / 255
            self.init(red: r, green: g, blue: b)
            return
        }
        self.init(red: 1, green: 0.18, blue: 0.33)
    }
}
#endif
