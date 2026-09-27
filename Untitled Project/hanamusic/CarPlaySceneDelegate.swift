import Foundation

#if os(iOS)
import CarPlay
import MediaPlayer

class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate, CPSearchTemplateDelegate, CPNowPlayingTemplateObserver {
    private var interfaceController: CPInterfaceController?
    private var searchTemplate: CPSearchTemplate?
    private let musicManager = MusicManager.shared

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        setupNowPlayingTemplate()
        setupCarPlayInterface()
        setupRemoteCommands()
        setupObservers()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        CPNowPlayingTemplate.shared.remove(self)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 1. 构建主界面（完全对齐 Apple Music CarPlay 官方推荐五栏结构）
    // 无设置和文件底栏，仅保留 Apple Music 标准功能
    private func setupCarPlayInterface() {
        guard let interfaceController = interfaceController else { return }

        // 1. 今すぐ聴く / 即刻聆听 (Listen Now)
        let listenNowTemplate = createListenNowTemplate()

        // 2. 资料库 (Library)
        let libraryTemplate = createLibraryTemplate()

        // 3. 播放列表 (Playlists) - 同步自建歌单与媒体库歌单
        let playlistsTemplate = createPlaylistsTemplate()

        // 4. 搜索 (Search)
        let search = CPSearchTemplate()
        search.delegate = self
        search.tabImage = UIImage(systemName: "magnifyingglass")
        search.tabTitle = L10n.menuSearch
        self.searchTemplate = search

        // 5. 正在播放 (Now Playing)
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        nowPlayingTemplate.tabImage = UIImage(systemName: "play.circle.fill")
        nowPlayingTemplate.tabTitle = L10n.nowPlaying

        let tabBar = CPTabBarTemplate(templates: [
            listenNowTemplate,
            libraryTemplate,
            playlistsTemplate,
            search,
            nowPlayingTemplate
        ])

        interfaceController.setRootTemplate(tabBar, animated: false, completion: nil)
    }

    // MARK: - 2. 「今すぐ聴く / 即刻聆听」模板 (Listen Now)
    private func createListenNowTemplate() -> CPListTemplate {
        // 喜爱曲目直达
        let favoriteSongs = musicManager.songs.filter { musicManager.isFavorite(song: $0) }
        let favoriteItem = CPListItem(
            text: L10n.favorites,
            detailText: L10n.songCount(favoriteSongs.count)
        )
        favoriteItem.setImage(UIImage(systemName: "heart.fill"))
        favoriteItem.handler = { [weak self] _, completion in
            if let self = self {
                self.openSongList(title: L10n.favorites, songs: favoriteSongs)
            }
            completion()
        }

        // 随机播放全部曲目快捷键
        let shuffleAllItem = CPListItem(
            text: L10n.shufflePlay,
            detailText: L10n.songCount(musicManager.songs.count)
        )
        shuffleAllItem.setImage(UIImage(systemName: "shuffle"))
        shuffleAllItem.handler = { [weak self] _, completion in
            if let self = self, let first = self.musicManager.songs.shuffled().first {
                self.musicManager.play(song: first, from: self.musicManager.songs.shuffled())
                self.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
            }
            completion()
        }

        let quickSection = CPListSection(items: [favoriteItem, shuffleAllItem], header: L10n.listenNow, sectionIndexTitle: nil)

        // 最近播放与添加专辑推荐
        let recentAlbums = musicManager.recentlyAddedAlbums.prefix(8)
        let recentItems: [CPListItem] = recentAlbums.map { album in
            let title = album.representativeItem?.albumTitle ?? "未知专辑"
            let artist = album.representativeItem?.artist ?? "未知艺术家"
            let item = CPListItem(text: title, detailText: artist)

            if let artwork = album.representativeItem?.artwork,
               let image = artwork.image(at: CGSize(width: 44, height: 44)) {
                item.setImage(image)
            } else {
                item.setImage(UIImage(systemName: "opticaldisc"))
            }

            item.handler = { [weak self] _, completion in
                self?.openCollectionDetail(title: title, collection: album)
                completion()
            }
            return item
        }

        let recentSection = CPListSection(items: recentItems, header: L10n.recentlyAdded, sectionIndexTitle: nil)

        let template = CPListTemplate(
            title: L10n.listenNow,
            sections: [quickSection, recentSection]
        )
        template.tabImage = UIImage(systemName: "play.circle.fill")
        return template
    }

    // MARK: - 3. 资料库模板 (Library)
    private func createLibraryTemplate() -> CPListTemplate {
        // 分类入口
        let playlistItem = CPListItem(text: L10n.tabPlaylists, detailText: L10n.playlistCount(musicManager.playlists.count + musicManager.customPlaylists.count))
        playlistItem.setImage(UIImage(systemName: "music.note.list"))
        playlistItem.handler = { [weak self] _, completion in
            if let self = self {
                self.interfaceController?.pushTemplate(self.createPlaylistsTemplate(), animated: true, completion: nil)
            }
            completion()
        }

        let artistItem = CPListItem(text: L10n.artists, detailText: L10n.artistCount(musicManager.artists.count))
        artistItem.setImage(UIImage(systemName: "music.mic"))
        artistItem.handler = { [weak self] _, completion in
            if let self = self {
                self.interfaceController?.pushTemplate(self.createArtistsTemplate(), animated: true, completion: nil)
            }
            completion()
        }

        let albumItem = CPListItem(text: L10n.albums, detailText: L10n.albumCount(musicManager.albums.count))
        albumItem.setImage(UIImage(systemName: "square.stack"))
        albumItem.handler = { [weak self] _, completion in
            if let self = self {
                self.interfaceController?.pushTemplate(self.createAlbumsTemplate(), animated: true, completion: nil)
            }
            completion()
        }

        let songItem = CPListItem(text: L10n.tabSongs, detailText: L10n.songCount(musicManager.songs.count))
        songItem.setImage(UIImage(systemName: "music.note"))
        songItem.handler = { [weak self] _, completion in
            if let self = self {
                self.interfaceController?.pushTemplate(self.createSongsTemplate(), animated: true, completion: nil)
            }
            completion()
        }

        let genreItem = CPListItem(text: L10n.genres, detailText: "\(musicManager.genres.count) 款风格")
        genreItem.setImage(UIImage(systemName: "guitars"))
        genreItem.handler = { [weak self] _, completion in
            if let self = self {
                self.interfaceController?.pushTemplate(self.createGenresTemplate(), animated: true, completion: nil)
            }
            completion()
        }

        let categorySection = CPListSection(items: [playlistItem, artistItem, albumItem, songItem, genreItem], header: "分类浏览", sectionIndexTitle: nil)

        // 最近添加专辑
        let recentAlbums = musicManager.recentlyAddedAlbums.prefix(12)
        let recentItems: [CPListItem] = recentAlbums.map { album in
            let title = album.representativeItem?.albumTitle ?? "未知专辑"
            let artist = album.representativeItem?.artist ?? "未知艺术家"
            let item = CPListItem(text: title, detailText: artist)

            if let artwork = album.representativeItem?.artwork,
               let image = artwork.image(at: CGSize(width: 44, height: 44)) {
                item.setImage(image)
            } else {
                item.setImage(UIImage(systemName: "opticaldisc"))
            }

            item.handler = { [weak self] _, completion in
                self?.openCollectionDetail(title: title, collection: album)
                completion()
            }
            return item
        }

        let recentSection = CPListSection(items: recentItems, header: L10n.recentlyAdded, sectionIndexTitle: nil)

        let template = CPListTemplate(
            title: L10n.tabLibrary,
            sections: [categorySection, recentSection]
        )
        template.tabImage = UIImage(systemName: "square.stack.fill")
        return template
    }

    // MARK: - 4. 歌单列表模板（深度整合用户自建歌单与系统歌单）
    private func createPlaylistsTemplate() -> CPListTemplate {
        var sections: [CPListSection] = []

        // 1. 用户自建歌单分区
        if !musicManager.customPlaylists.isEmpty {
            let customItems: [CPListItem] = musicManager.customPlaylists.map { custom in
                let item = CPListItem(
                    text: custom.name,
                    detailText: L10n.songCount(custom.songPersistentIDs.count)
                )
                item.setImage(UIImage(systemName: custom.coverSymbol) ?? UIImage(systemName: "music.note.list"))
                item.handler = { [weak self] _, completion in
                    self?.openCustomPlaylistDetail(custom: custom)
                    completion()
                }
                return item
            }
            sections.append(CPListSection(items: customItems, header: L10n.customPlaylists, sectionIndexTitle: nil))
        }

        // 2. 媒体库/iTunes歌单分区
        let libraryPlaylists = musicManager.playlists
        let playlistItems: [CPListItem] = libraryPlaylists.map { playlist in
            let name = playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "未命名歌单"
            let countText = L10n.songCount(playlist.count)
            let item = CPListItem(text: name, detailText: countText)

            if let artwork = playlist.representativeItem?.artwork,
               let image = artwork.image(at: CGSize(width: 40, height: 40)) {
                item.setImage(image)
            } else {
                item.setImage(UIImage(systemName: "music.note.list"))
            }

            item.handler = { [weak self] _, completion in
                self?.openCollectionDetail(title: name, collection: playlist)
                completion()
            }
            return item
        }
        sections.append(CPListSection(items: playlistItems, header: "媒体库歌单", sectionIndexTitle: nil))

        let template = CPListTemplate(title: L10n.tabPlaylists, sections: sections)
        template.tabImage = UIImage(systemName: "music.note.list")
        return template
    }

    // 打开自建歌单详情
    private func openCustomPlaylistDetail(custom: CustomPlaylist) {
        let songs = musicManager.songs.filter { custom.songPersistentIDs.contains($0.persistentID) }
        openSongList(title: custom.name, songs: songs)
    }

    // MARK: - 5. 艺术家列表模板
    private func createArtistsTemplate() -> CPListTemplate {
        let artists = musicManager.artists
        let items: [CPListItem] = artists.map { artist in
            let name = artist.representativeItem?.artist ?? "未知艺术家"
            let item = CPListItem(text: name, detailText: L10n.songCount(artist.count))
            if let artwork = artist.representativeItem?.artwork,
               let image = artwork.image(at: CGSize(width: 40, height: 40)) {
                item.setImage(image)
            } else {
                item.setImage(UIImage(systemName: "person.circle"))
            }
            item.handler = { [weak self] _, completion in
                self?.openCollectionDetail(title: name, collection: artist)
                completion()
            }
            return item
        }

        return CPListTemplate(title: L10n.artists, sections: [CPListSection(items: items)])
    }

    // MARK: - 6. 专辑列表模板
    private func createAlbumsTemplate() -> CPListTemplate {
        let albums = musicManager.albums
        let items: [CPListItem] = albums.map { album in
            let title = album.representativeItem?.albumTitle ?? "未知专辑"
            let artist = album.representativeItem?.artist ?? "未知艺术家"
            let item = CPListItem(text: title, detailText: "\(artist) · \(album.count) 首")

            if let artwork = album.representativeItem?.artwork,
               let image = artwork.image(at: CGSize(width: 40, height: 40)) {
                item.setImage(image)
            } else {
                item.setImage(UIImage(systemName: "opticaldisc"))
            }

            item.handler = { [weak self] _, completion in
                self?.openCollectionDetail(title: title, collection: album)
                completion()
            }
            return item
        }

        return CPListTemplate(title: L10n.albums, sections: [CPListSection(items: items)])
    }

    // MARK: - 7. 歌曲列表模板
    private func createSongsTemplate() -> CPListTemplate {
        let songs = musicManager.songs
        let items: [CPListItem] = songs.prefix(120).map { song in
            let item = CPListItem(
                text: song.title ?? "未知曲目",
                detailText: song.artist ?? "未知艺术家"
            )
            if let artwork = song.artwork,
               let image = artwork.image(at: CGSize(width: 40, height: 40)) {
                item.setImage(image)
            } else {
                item.setImage(UIImage(systemName: "music.note"))
            }

            if musicManager.currentSong?.persistentID == song.persistentID {
                item.isPlaying = musicManager.isPlaying
            }

            item.handler = { [weak self] _, completion in
                self?.musicManager.play(song: song, from: songs)
                self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
                completion()
            }
            return item
        }

        return CPListTemplate(title: L10n.tabSongs, sections: [CPListSection(items: items)])
    }

    // MARK: - 8. 音乐流派模板
    private func createGenresTemplate() -> CPListTemplate {
        let genres = musicManager.genres
        let items: [CPListItem] = genres.map { genre in
            let name = genre.representativeItem?.genre ?? "未知流派"
            let item = CPListItem(text: name, detailText: L10n.songCount(genre.count))
            if let artwork = genre.representativeItem?.artwork,
               let image = artwork.image(at: CGSize(width: 40, height: 40)) {
                item.setImage(image)
            } else {
                item.setImage(UIImage(systemName: "guitars"))
            }
            item.handler = { [weak self] _, completion in
                self?.openCollectionDetail(title: name, collection: genre)
                completion()
            }
            return item
        }

        return CPListTemplate(title: L10n.genres, sections: [CPListSection(items: items)])
    }

    // MARK: - 统一曲目列表展示
    private func openSongList(title: String, songs: [MPMediaItem]) {
        let playAllItem = CPListItem(text: "\(L10n.playAll) (\(songs.count))", detailText: nil)
        playAllItem.setImage(UIImage(systemName: "play.circle.fill"))
        playAllItem.handler = { [weak self] _, completion in
            if let first = songs.first {
                self?.musicManager.play(song: first, from: songs)
                self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
            }
            completion()
        }

        let shuffleItem = CPListItem(text: L10n.shufflePlay, detailText: nil)
        shuffleItem.setImage(UIImage(systemName: "shuffle"))
        shuffleItem.handler = { [weak self] _, completion in
            if let first = songs.shuffled().first {
                self?.musicManager.play(song: first, from: songs.shuffled())
                self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
            }
            completion()
        }

        let actionSection = CPListSection(items: [playAllItem, shuffleItem])

        let songItems: [CPListItem] = songs.enumerated().map { index, song in
            let item = CPListItem(
                text: "\(index + 1). " + (song.title ?? "未知曲目"),
                detailText: song.artist ?? "未知艺术家"
            )
            if let artwork = song.artwork,
               let image = artwork.image(at: CGSize(width: 40, height: 40)) {
                item.setImage(image)
            }

            if musicManager.currentSong?.persistentID == song.persistentID {
                item.isPlaying = musicManager.isPlaying
            }

            item.handler = { [weak self] _, completion in
                self?.musicManager.play(song: song, from: songs)
                self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
                completion()
            }
            return item
        }

        let trackSection = CPListSection(items: songItems)
        let template = CPListTemplate(title: title, sections: [actionSection, trackSection])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    private func openCollectionDetail(title: String, collection: MPMediaItemCollection) {
        openSongList(title: title, songs: collection.items)
    }

    // MARK: - 9. Apple Music 规范正在播放界面配置（心形喜爱、随机、循环、待播清单、专辑/艺人跳转）
    private func setupNowPlayingTemplate() {
        let nowPlaying = CPNowPlayingTemplate.shared
        nowPlaying.isAlbumArtistButtonEnabled = true
        nowPlaying.isUpNextButtonEnabled = true
        nowPlaying.upNextTitle = "待播清单"
        nowPlaying.add(self)

        updateNowPlayingButtons()
    }

    private func updateNowPlayingButtons() {
        let nowPlaying = CPNowPlayingTemplate.shared

        // 1. 随机播放按键
        let shuffleBtn = CPNowPlayingShuffleButton { [weak self] _ in
            self?.musicManager.toggleShuffle()
            self?.updateNowPlayingButtons()
        }

        // 2. 循环播放按键
        let repeatBtn = CPNowPlayingRepeatButton { [weak self] _ in
            self?.musicManager.toggleRepeat()
            self?.updateNowPlayingButtons()
        }

        // 3. 心形喜欢按钮（与手机端收藏状态实时双向同步）
        let isFav = musicManager.currentSong.map { musicManager.isFavorite(song: $0) } ?? false
        let heartImage = UIImage(systemName: isFav ? "heart.fill" : "heart") ?? UIImage()
        let favoriteBtn = CPNowPlayingImageButton(image: heartImage) { [weak self] _ in
            if let self = self, let song = self.musicManager.currentSong {
                self.musicManager.toggleFavorite(song: song)
                self.updateNowPlayingButtons()
            }
        }

        nowPlaying.updateNowPlayingButtons([shuffleBtn, favoriteBtn, repeatBtn])
    }

    // MARK: - CPNowPlayingTemplateObserver 交互代理
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        let queueSongs = musicManager.songs
        guard !queueSongs.isEmpty else { return }

        let items: [CPListItem] = queueSongs.prefix(50).map { song in
            let item = CPListItem(text: song.title ?? "未知曲目", detailText: song.artist ?? "未知艺术家")
            if let artwork = song.artwork, let image = artwork.image(at: CGSize(width: 40, height: 40)) {
                item.setImage(image)
            }
            if musicManager.currentSong?.persistentID == song.persistentID {
                item.isPlaying = musicManager.isPlaying
            }
            item.handler = { [weak self] _, completion in
                self?.musicManager.play(song: song, from: queueSongs)
                self?.interfaceController?.popTemplate(animated: true, completion: nil)
                completion()
            }
            return item
        }

        let template = CPListTemplate(title: "待播清单", sections: [CPListSection(items: items)])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        guard let currentSong = musicManager.currentSong else { return }

        if let albumTitle = currentSong.albumTitle,
           let matchedAlbum = musicManager.albums.first(where: { $0.representativeItem?.albumTitle == albumTitle }) {
            openCollectionDetail(title: albumTitle, collection: matchedAlbum)
        } else if let artist = currentSong.artist,
                  let matchedArtist = musicManager.artists.first(where: { $0.representativeItem?.artist == artist }) {
            openCollectionDetail(title: artist, collection: matchedArtist)
        }
    }

    // MARK: - 10. 车载搜索代理 (CPSearchTemplateDelegate)
    func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        if searchText.isEmpty {
            completionHandler([])
            return
        }

        var results: [CPListItem] = []

        // 搜索歌曲
        let matchedSongs = musicManager.songs.filter {
            ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        for song in matchedSongs.prefix(8) {
            let item = CPListItem(text: song.title ?? "未知曲目", detailText: "歌曲 · " + (song.artist ?? "未知艺术家"))
            if let artwork = song.artwork, let image = artwork.image(at: CGSize(width: 40, height: 40)) {
                item.setImage(image)
            } else {
                item.setImage(UIImage(systemName: "music.note"))
            }
            item.handler = { [weak self] _, completion in
                self?.musicManager.play(song: song, from: matchedSongs)
                self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
                completion()
            }
            results.append(item)
        }

        // 搜索专辑
        let matchedAlbums = musicManager.albums.filter {
            ($0.representativeItem?.albumTitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.representativeItem?.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        for album in matchedAlbums.prefix(4) {
            let title = album.representativeItem?.albumTitle ?? "未知专辑"
            let artist = album.representativeItem?.artist ?? "未知艺术家"
            let item = CPListItem(text: title, detailText: "专辑 · \(artist)")
            if let artwork = album.representativeItem?.artwork, let image = artwork.image(at: CGSize(width: 40, height: 40)) {
                item.setImage(image)
            } else {
                item.setImage(UIImage(systemName: "opticaldisc"))
            }
            item.handler = { [weak self] _, completion in
                self?.openCollectionDetail(title: title, collection: album)
                completion()
            }
            results.append(item)
        }

        completionHandler(results)
    }

    func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    // MARK: - 11. 状态监听与同步
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackChange),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackChange),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: nil
        )
    }

    @objc private func handlePlaybackChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateNowPlayingButtons()
        }
    }

    // MARK: - 12. 系统按键配置
    private func setupRemoteCommands() {
        musicManager.setupRemoteCommands()
    }
}
#endif
