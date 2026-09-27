import Foundation
import Combine

#if os(iOS)
import MediaPlayer
import AVFoundation
import UIKit

// MARK: - 本地音频模型（支持沙盒文件、Wi-Fi/数据线/AirDrop导入音频）
struct LocalAudioTrack: Identifiable, Equatable {
    var id: String { url.absoluteString }
    let url: URL
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var artworkImage: UIImage?

    static func extractMetadata(from url: URL) -> LocalAudioTrack {
        let asset = AVAsset(url: url)
        var title = url.deletingPathExtension().lastPathComponent
        var artist = L10n.unknownArtist
        var album = "Hana Music"
        var artworkImage: UIImage?
        let durationSeconds = CMTimeGetSeconds(asset.duration)

        for item in asset.commonMetadata {
            if let key = item.commonKey?.rawValue {
                switch key {
                case "title":
                    if let val = item.stringValue, !val.isEmpty { title = val }
                case "artist":
                    if let val = item.stringValue, !val.isEmpty { artist = val }
                case "albumName":
                    if let val = item.stringValue, !val.isEmpty { album = val }
                case "artwork":
                    if let data = item.dataValue, let img = UIImage(data: data) {
                        artworkImage = img
                    }
                default:
                    break
                }
            }
        }

        return LocalAudioTrack(
            url: url,
            title: title,
            artist: artist,
            album: album,
            duration: durationSeconds.isFinite && durationSeconds > 0 ? durationSeconds : 0,
            artworkImage: artworkImage
        )
    }
}

struct CustomPlaylist: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var songPersistentIDs: [UInt64] = []
    var coverSymbol: String = "music.note.list"
    var coverColorHex: String = "#FF2D55"
    var createdAt: Date = Date()
}

enum SongSortOption: String, CaseIterable, Identifiable {
    case title = "按标题"
    case artist = "按艺术家"
    case dateAdded = "按添加时间"
    var id: String { rawValue }
}

enum MediaSourceOption: String, CaseIterable, Identifiable {
    case all = "全部"
    case local = "本地文件"
    case itunes = "iTunes 媒体库"
    var id: String { rawValue }
}

class MusicManager: NSObject, ObservableObject {
    static let shared = MusicManager()

    // 歌曲与分类数据
    @Published var songs: [MPMediaItem] = []
    @Published var playlists: [MPMediaItemCollection] = []
    @Published var albums: [MPMediaItemCollection] = []
    @Published var recentlyAddedAlbums: [MPMediaItemCollection] = []
    @Published var artists: [MPMediaItemCollection] = []
    @Published var genres: [MPMediaItemCollection] = []
    @Published var favoriteSongIDs: Set<UInt64> = []

    // 用户自定义播放列表
    @Published var customPlaylists: [CustomPlaylist] = []

    // 排序与媒体源选项
    @Published var songSortOption: SongSortOption = .title
    @Published var mediaSourceFilter: MediaSourceOption = .all

    // 本地音频扫描与外部导入音轨
    @Published var isScanningLocalAudio: Bool = false
    @Published var scannedLocalFiles: [URL] = []
    @Published var localTracks: [LocalAudioTrack] = []
    @Published var scanResultMessage: String?
    @Published var showScanResultAlert: Bool = false

    // iTunes 同步状态
    @Published var isSyncingITunes: Bool = false
    @Published var iTunesSyncResultMessage: String?
    @Published var showITunesSyncAlert: Bool = false

    // 当前播放核心状态
    @Published var currentSong: MPMediaItem?
    @Published var currentLocalTrack: LocalAudioTrack?
    @Published var isPlaying: Bool = false
    @Published var currentPlaybackTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var shuffleMode: MPMusicShuffleMode = .off
    @Published var repeatMode: MPMusicRepeatMode = .none
    @Published var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined

    // 拖动进度条标记（拖动时不被计时器覆写）
    var isScrubbing: Bool = false

    // 统一访问器：当前播放曲目的标题、艺术家、专辑与封面
    var currentTitle: String {
        currentLocalTrack?.title ?? currentSong?.title ?? L10n.unknownTrack
    }

    var currentArtist: String {
        currentLocalTrack?.artist ?? currentSong?.artist ?? L10n.unknownArtist
    }

    var currentAlbum: String {
        currentLocalTrack?.album ?? currentSong?.albumTitle ?? L10n.unknownAlbum
    }

    var currentArtworkImage: UIImage? {
        if let localImg = currentLocalTrack?.artworkImage {
            return localImg
        }
        if let song = currentSong, let artwork = song.artwork {
            return artwork.image(at: CGSize(width: 500, height: 500))
        }
        return nil
    }

    // MARK: - 独立本地音频引擎（AVPlayer 主引擎，彻底告别调用系统 Apple Music）
    private var avPlayer: AVPlayer?
    private var avTimeObserverToken: Any?

    // 仅在遇到带系统 DRM 保护的 iPod 库曲目时作为应用内保底播放器，绝不调用 systemMusicPlayer
    private let inAppPlayer = MPMusicPlayerController.applicationQueuePlayer
    private var progressCancellable: AnyCancellable?

    // 播放队列缓存
    private var currentSongQueue: [MPMediaItem] = []
    private var currentLocalQueue: [LocalAudioTrack] = []

    override init() {
        super.init()
        loadFavorites()
        configureAudioSession()
        checkAuthorization()
        setupRemoteCommands()
        setupNotifications()
        startProgressTimer()
        scanSandboxAudioSilently()
    }

    deinit {
        removeAVPlayerTimeObserver()
        NotificationCenter.default.removeObserver(self)
        progressCancellable?.cancel()
    }

    // MARK: - 后台播放与音频会话配置（确保 Hana Music 自主发声，锁屏与后台持续播放）
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, policy: .longFormAudio, options: [])
            try session.setActive(true)
        } catch {
            print("AVAudioSession 配置失败: \(error)")
        }
    }

    // MARK: - 核心播放接口：播放媒体库歌曲（优先通过 AVPlayer 本地解析播放）
    func play(song: MPMediaItem, from collection: [MPMediaItem]? = nil) {
        let queueItems = collection ?? songs
        currentSongQueue = queueItems
        currentLocalTrack = nil
        currentSong = song
        duration = song.playbackDuration > 0 ? song.playbackDuration : 0
        currentPlaybackTime = 0

        // 优先检查本地 assetURL（无 DRM 的本地音频或已同步曲目）
        if let assetURL = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL {
            inAppPlayer.stop()
            playViaAVPlayer(url: assetURL, totalDuration: song.playbackDuration)
        } else {
            // 系统保护曲目使用应用内本地播放器 applicationQueuePlayer，绝不调用系统 Apple Music
            stopAVPlayer()
            let mediaCollection = MPMediaItemCollection(items: queueItems)
            inAppPlayer.setQueue(with: mediaCollection)
            inAppPlayer.nowPlayingItem = song
            inAppPlayer.play()
            isPlaying = true
        }

        updateNowPlayingInfo()
    }

    func playAll(collection: MPMediaItemCollection, shuffle: Bool = false) {
        var items = collection.items
        guard let first = items.first else { return }
        if shuffle {
            items.shuffle()
            shuffleMode = .songs
        } else {
            shuffleMode = .off
        }
        play(song: first, from: items)
    }

    // MARK: - 核心播放接口：播放本地导入音频文件（Documents、Wi-Fi、数据线传输、AirDrop）
    func play(localTrack: LocalAudioTrack, from list: [LocalAudioTrack]? = nil) {
        currentLocalQueue = list ?? localTracks
        currentSong = nil
        currentLocalTrack = localTrack
        duration = localTrack.duration
        currentPlaybackTime = 0

        inAppPlayer.stop()
        playViaAVPlayer(url: localTrack.url, totalDuration: localTrack.duration)
        updateNowPlayingInfo()
    }

    func play(url: URL) {
        let track = LocalAudioTrack.extractMetadata(from: url)
        if !localTracks.contains(where: { $0.url == url }) {
            localTracks.insert(track, at: 0)
        }
        play(localTrack: track, from: localTracks)
    }

    // MARK: - AVPlayer 本地音频执行引擎
    private func playViaAVPlayer(url: URL, totalDuration: TimeInterval) {
        stopAVPlayer()
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        avPlayer = player

        // 监听音轨播放结束通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAVPlayerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        setupAVPlayerTimeObserver()
        player.play()
        isPlaying = true

        // 异步修正精确时长
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let asset = AVAsset(url: url)
            let seconds = CMTimeGetSeconds(asset.duration)
            if seconds.isFinite && seconds > 0 {
                DispatchQueue.main.async {
                    self?.duration = seconds
                    self?.updateNowPlayingInfo()
                }
            }
        }
    }

    private func stopAVPlayer() {
        removeAVPlayerTimeObserver()
        if let player = avPlayer {
            player.pause()
            if let currentItem = player.currentItem {
                NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
            }
        }
        avPlayer = nil
    }

    private func setupAVPlayerTimeObserver() {
        removeAVPlayerTimeObserver()
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        avTimeObserverToken = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, self.isPlaying, !self.isScrubbing else { return }
            let current = CMTimeGetSeconds(time)
            if current.isFinite {
                self.currentPlaybackTime = max(0, current)
            }
        }
    }

    private func removeAVPlayerTimeObserver() {
        if let token = avTimeObserverToken, let player = avPlayer {
            player.removeTimeObserver(token)
            avTimeObserverToken = nil
        }
    }

    @objc private func handleAVPlayerDidFinish() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch self.repeatMode {
            case .one:
                self.seek(to: 0)
                self.avPlayer?.play()
                self.isPlaying = true
            case .all, .none, .default:
                self.playNext()
            @unknown default:
                self.isPlaying = false
            }
        }
    }

    // MARK: - 基础播放控制
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func pause() {
        avPlayer?.pause()
        inAppPlayer.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func resume() {
        if let player = avPlayer {
            player.play()
            isPlaying = true
        } else if inAppPlayer.playbackState == .paused || inAppPlayer.nowPlayingItem != nil {
            inAppPlayer.play()
            isPlaying = true
        } else if let song = songs.first {
            play(song: song)
        } else if let local = localTracks.first {
            play(localTrack: local)
        }
        updateNowPlayingInfo()
    }

    func playNext() {
        if let currentLocal = currentLocalTrack, !currentLocalQueue.isEmpty {
            if let idx = currentLocalQueue.firstIndex(where: { $0.url == currentLocal.url }) {
                let nextIdx = (idx + 1) % currentLocalQueue.count
                play(localTrack: currentLocalQueue[nextIdx], from: currentLocalQueue)
                return
            }
        }

        if let current = currentSong, !currentSongQueue.isEmpty {
            if let idx = currentSongQueue.firstIndex(where: { $0.persistentID == current.persistentID }) {
                let nextIdx = (idx + 1) % currentSongQueue.count
                play(song: currentSongQueue[nextIdx], from: currentSongQueue)
                return
            }
        }

        if let next = songs.first {
            play(song: next)
        }
    }

    func playPrevious() {
        if currentPlaybackTime > 3.0 {
            seek(to: 0)
            return
        }

        if let currentLocal = currentLocalTrack, !currentLocalQueue.isEmpty {
            if let idx = currentLocalQueue.firstIndex(where: { $0.url == currentLocal.url }) {
                let prevIdx = (idx - 1 + currentLocalQueue.count) % currentLocalQueue.count
                play(localTrack: currentLocalQueue[prevIdx], from: currentLocalQueue)
                return
            }
        }

        if let current = currentSong, !currentSongQueue.isEmpty {
            if let idx = currentSongQueue.firstIndex(where: { $0.persistentID == current.persistentID }) {
                let prevIdx = (idx - 1 + currentSongQueue.count) % currentSongQueue.count
                play(song: currentSongQueue[prevIdx], from: currentSongQueue)
                return
            }
        }

        seek(to: 0)
    }

    func seek(to time: TimeInterval) {
        let target = max(0, min(time, duration > 0 ? duration : 3600))
        currentPlaybackTime = target

        if let player = avPlayer {
            let cmTime = CMTime(seconds: target, preferredTimescale: 600)
            player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        } else {
            inAppPlayer.currentPlaybackTime = target
        }
        updateNowPlayingInfo()
    }

    func toggleShuffle() {
        if shuffleMode == .off {
            shuffleMode = .songs
            inAppPlayer.shuffleMode = .songs
            if !currentSongQueue.isEmpty {
                currentSongQueue.shuffle()
            }
        } else {
            shuffleMode = .off
            inAppPlayer.shuffleMode = .off
        }
        updateNowPlayingInfo()
    }

    func toggleRepeat() {
        switch repeatMode {
        case .none, .default:
            repeatMode = .all
            inAppPlayer.repeatMode = .all
        case .all:
            repeatMode = .one
            inAppPlayer.repeatMode = .one
        case .one:
            repeatMode = .none
            inAppPlayer.repeatMode = .none
        @unknown default:
            repeatMode = .none
            inAppPlayer.repeatMode = .none
        }
        updateNowPlayingInfo()
    }

    // MARK: - 收藏与自定义歌单
    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: "hana_favorite_song_ids") as? [UInt64] {
            self.favoriteSongIDs = Set(saved)
        }
        loadCustomPlaylists()
    }

    func isFavorite(song: MPMediaItem) -> Bool {
        favoriteSongIDs.contains(song.persistentID)
    }

    func toggleFavorite(song: MPMediaItem) {
        if favoriteSongIDs.contains(song.persistentID) {
            favoriteSongIDs.remove(song.persistentID)
        } else {
            favoriteSongIDs.insert(song.persistentID)
        }
        let array = Array(favoriteSongIDs)
        UserDefaults.standard.set(array, forKey: "hana_favorite_song_ids")
        updateNowPlayingInfo()
    }

    func playNext(song: MPMediaItem) {
        guard let current = currentSong,
              let currentIndex = songs.firstIndex(where: { $0.persistentID == current.persistentID }) else {
            play(song: song)
            return
        }
        var newQueue = songs
        if let existing = newQueue.firstIndex(where: { $0.persistentID == song.persistentID }) {
            newQueue.remove(at: existing)
        }
        let insertIndex = min(currentIndex + 1, newQueue.count)
        newQueue.insert(song, at: insertIndex)
        songs = newQueue
    }

    func removeSong(_ song: MPMediaItem) {
        songs.removeAll(where: { $0.persistentID == song.persistentID })
    }

    func createCustomPlaylist(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newPlaylist = CustomPlaylist(name: trimmed)
        customPlaylists.insert(newPlaylist, at: 0)
        saveCustomPlaylists()
    }

    func deleteCustomPlaylist(id: UUID) {
        customPlaylists.removeAll { $0.id == id }
        saveCustomPlaylists()
    }

    func renameCustomPlaylist(id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let idx = customPlaylists.firstIndex(where: { $0.id == id }) {
            customPlaylists[idx].name = trimmed
            saveCustomPlaylists()
        }
    }

    func addSongToCustomPlaylist(playlistID: UUID, song: MPMediaItem) {
        if let idx = customPlaylists.firstIndex(where: { $0.id == playlistID }) {
            if !customPlaylists[idx].songPersistentIDs.contains(song.persistentID) {
                customPlaylists[idx].songPersistentIDs.append(song.persistentID)
                saveCustomPlaylists()
            }
        }
    }

    func generateCover(for playlistID: UUID) {
        let colors = ["#FF2D55", "#5856D6", "#AF52DE", "#007AFF", "#34C759", "#FF9500", "#FF3B30", "#5AC8FA"]
        let symbols = ["sparkles", "music.note", "guitars.fill", "star.fill", "heart.fill", "flame.fill", "waveform"]
        if let idx = customPlaylists.firstIndex(where: { $0.id == playlistID }) {
            customPlaylists[idx].coverColorHex = colors.randomElement() ?? "#FF2D55"
            customPlaylists[idx].coverSymbol = symbols.randomElement() ?? "sparkles"
            saveCustomPlaylists()
        }
    }

    private func loadCustomPlaylists() {
        if let data = UserDefaults.standard.data(forKey: "hana_custom_playlists"),
           let decoded = try? JSONDecoder().decode([CustomPlaylist].self, from: data) {
            self.customPlaylists = decoded
        }
    }

    private func saveCustomPlaylists() {
        if let encoded = try? JSONEncoder().encode(customPlaylists) {
            UserDefaults.standard.set(encoded, forKey: "hana_custom_playlists")
        }
    }

    // MARK: - 锁屏、控制中心与 CarPlay NowPlaying 独立信息同步
    func updateNowPlayingInfo() {
        var info: [String: Any] = [:]

        if let local = currentLocalTrack {
            info[MPMediaItemPropertyTitle] = local.title
            info[MPMediaItemPropertyArtist] = local.artist
            info[MPMediaItemPropertyAlbumTitle] = local.album
            info[MPMediaItemPropertyPlaybackDuration] = duration > 0 ? duration : local.duration
            if let img = local.artworkImage {
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
            }
        } else if let song = currentSong {
            info[MPMediaItemPropertyTitle] = song.title ?? ""
            info[MPMediaItemPropertyArtist] = song.artist ?? ""
            info[MPMediaItemPropertyAlbumTitle] = song.albumTitle ?? ""
            info[MPMediaItemPropertyPlaybackDuration] = duration > 0 ? duration : song.playbackDuration
            if let artwork = song.artwork {
                info[MPMediaItemPropertyArtwork] = artwork
            }
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentPlaybackTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        let isFav = currentSong.map { isFavorite(song: $0) } ?? false
        MPRemoteCommandCenter.shared().likeCommand.isActive = isFav
    }

    // MARK: - 锁屏与系统远程指令响应配置
    func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }

        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }

        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: positionEvent.positionTime)
            return .success
        }

        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.seek(to: self.currentPlaybackTime + 15)
            return .success
        }

        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.seek(to: self.currentPlaybackTime - 15)
            return .success
        }

        center.likeCommand.isEnabled = true
        center.likeCommand.addTarget { [weak self] _ in
            guard let self = self, let song = self.currentSong else { return .noSuchContent }
            self.toggleFavorite(song: song)
            return .success
        }
    }

    // MARK: - 权限与数据加载
    func checkAuthorization() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        switch authorizationStatus {
        case .authorized:
            loadAllMedia()
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    self?.authorizationStatus = status
                    if status == .authorized {
                        self?.loadAllMedia()
                    }
                }
            }
        default:
            break
        }
    }

    func loadAllMedia() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let songQuery = MPMediaQuery.songs()
            let allSongs = songQuery.items ?? []

            let playlistQuery = MPMediaQuery.playlists()
            let allPlaylists = playlistQuery.collections ?? []

            let albumQuery = MPMediaQuery.albums()
            let allAlbums = albumQuery.collections ?? []

            let recentAlbums = allAlbums.sorted { col1, col2 in
                let date1 = col1.representativeItem?.value(forProperty: MPMediaItemPropertyDateAdded) as? Date ?? Date.distantPast
                let date2 = col2.representativeItem?.value(forProperty: MPMediaItemPropertyDateAdded) as? Date ?? Date.distantPast
                return date1 > date2
            }

            let artistQuery = MPMediaQuery.artists()
            let allArtists = artistQuery.collections ?? []

            let genreQuery = MPMediaQuery.genres()
            let allGenres = genreQuery.collections ?? []

            DispatchQueue.main.async {
                self.songs = allSongs
                self.playlists = allPlaylists
                self.albums = allAlbums
                self.recentlyAddedAlbums = recentAlbums
                self.artists = allArtists
                self.genres = allGenres
            }
        }
    }

    // MARK: - 本地音频扫描功能
    func scanSandboxAudioSilently() {
        scanLocalAudioFiles(showFeedback: false)
    }

    func scanLocalAudioFiles(showFeedback: Bool = true, completion: (([URL]) -> Void)? = nil) {
        if showFeedback { isScanningLocalAudio = true }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let fileManager = FileManager.default
            var foundURLs: [URL] = []
            let audioExtensions = ["mp3", "m4a", "flac", "wav", "aac", "alac", "aif", "aiff", "ogg"]

            if let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                foundURLs.append(contentsOf: self.findAudioFiles(in: docURL, extensions: audioExtensions))
            }
            if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                foundURLs.append(contentsOf: self.findAudioFiles(in: cacheURL, extensions: audioExtensions))
            }

            let tracks = foundURLs.map { LocalAudioTrack.extractMetadata(from: $0) }

            DispatchQueue.main.async {
                self.scannedLocalFiles = foundURLs
                self.localTracks = tracks
                self.isScanningLocalAudio = false
                if showFeedback {
                    if foundURLs.isEmpty {
                        self.scanResultMessage = "本地扫描完成：沙盒中暂未发现新增音频文件。\n您可通过“打开文件”导入外部音频。"
                    } else {
                        self.scanResultMessage = "本地扫描完成！共找到 \(foundURLs.count) 个本地音频文件，已更新至曲目列表。"
                    }
                    self.showScanResultAlert = true
                }
                completion?(foundURLs)
            }
        }
    }

    private func findAudioFiles(in directory: URL, extensions: [String]) -> [URL] {
        var results: [URL] = []
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return results
        }
        for case let fileURL as URL in enumerator {
            if extensions.contains(fileURL.pathExtension.lowercased()) {
                results.append(fileURL)
            }
        }
        return results
    }

    func syncWithITunesLibrary(completion: (() -> Void)? = nil) {
        isSyncingITunes = true
        MPMediaLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            if status == .authorized {
                DispatchQueue.global(qos: .userInitiated).async {
                    let songQuery = MPMediaQuery.songs()
                    let allSongs = songQuery.items ?? []
                    let playlistQuery = MPMediaQuery.playlists()
                    let allPlaylists = playlistQuery.collections ?? []
                    let albumQuery = MPMediaQuery.albums()
                    let allAlbums = albumQuery.collections ?? []

                    let recentAlbums = allAlbums.sorted { col1, col2 in
                        let date1 = col1.representativeItem?.value(forProperty: MPMediaItemPropertyDateAdded) as? Date ?? Date.distantPast
                        let date2 = col2.representativeItem?.value(forProperty: MPMediaItemPropertyDateAdded) as? Date ?? Date.distantPast
                        return date1 > date2
                    }

                    let artistQuery = MPMediaQuery.artists()
                    let allArtists = artistQuery.collections ?? []
                    let genreQuery = MPMediaQuery.genres()
                    let allGenres = genreQuery.collections ?? []

                    DispatchQueue.main.async {
                        self.songs = allSongs
                        self.playlists = allPlaylists
                        self.albums = allAlbums
                        self.recentlyAddedAlbums = recentAlbums
                        self.artists = allArtists
                        self.genres = allGenres
                        self.isSyncingITunes = false
                        self.iTunesSyncResultMessage = "iTunes 音乐库同步成功！\n共同步 \(allSongs.count) 首歌曲、\(allAlbums.count) 张专辑、\(allPlaylists.count) 个歌单。"
                        self.showITunesSyncAlert = true
                        completion?()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isSyncingITunes = false
                    self.iTunesSyncResultMessage = "未能获取 Apple Music 媒体资料库权限，请在系统设置中允许 Hana Music 访问音乐资料库。"
                    self.showITunesSyncAlert = true
                }
            }
        }
    }

    private func startProgressTimer() {
        progressCancellable = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isPlaying, !self.isScrubbing else { return }
                if self.avPlayer == nil {
                    self.currentPlaybackTime = self.inAppPlayer.currentPlaybackTime
                }
            }
    }

    private func setupNotifications() {
        inAppPlayer.beginGeneratingPlaybackNotifications()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInAppNowPlayingItemChange),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: inAppPlayer
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInAppPlaybackStateChange),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: inAppPlayer
        )
    }

    @objc private func handleInAppNowPlayingItemChange() {
        guard avPlayer == nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentSong = self.inAppPlayer.nowPlayingItem
            self.duration = self.currentSong?.playbackDuration ?? 0
            if !self.isScrubbing {
                self.currentPlaybackTime = self.inAppPlayer.currentPlaybackTime
            }
            self.updateNowPlayingInfo()
        }
    }

    @objc private func handleInAppPlaybackStateChange() {
        guard avPlayer == nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isPlaying = (self.inAppPlayer.playbackState == .playing)
            self.updateNowPlayingInfo()
        }
    }
}

#else

struct LocalAudioTrack: Identifiable, Equatable {
    var id: String { url.absoluteString }
    let url: URL
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
}

struct CustomPlaylist: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var songPersistentIDs: [UInt64] = []
    var coverSymbol: String = "music.note.list"
    var coverColorHex: String = "#FF2D55"
    var createdAt: Date = Date()
}

enum SongSortOption: String, CaseIterable, Identifiable {
    case title = "按标题"
    case artist = "按艺术家"
    case dateAdded = "按添加时间"
    var id: String { rawValue }
}

enum MediaSourceOption: String, CaseIterable, Identifiable {
    case all = "全部"
    case local = "本地文件"
    case itunes = "iTunes 媒体库"
    var id: String { rawValue }
}

class MusicManager: ObservableObject {
    static let shared = MusicManager()
    @Published var isPlaying: Bool = false
    @Published var currentPlaybackTime: Double = 0
    @Published var duration: Double = 0
    @Published var customPlaylists: [CustomPlaylist] = []
    @Published var songSortOption: SongSortOption = .title
    @Published var mediaSourceFilter: MediaSourceOption = .all
    @Published var isScanningLocalAudio: Bool = false
    @Published var scannedLocalFiles: [URL] = []
    @Published var localTracks: [LocalAudioTrack] = []
    @Published var scanResultMessage: String?
    @Published var showScanResultAlert: Bool = false
    @Published var isSyncingITunes: Bool = false
    @Published var iTunesSyncResultMessage: String?
    @Published var showITunesSyncAlert: Bool = false

    var currentTitle: String { "Demo Track" }
    var currentArtist: String { "Demo Artist" }
    var currentAlbum: String { "Demo Album" }

    func scanLocalAudioFiles(showFeedback: Bool = true, completion: (([URL]) -> Void)? = nil) {}
    func syncWithITunesLibrary(completion: (() -> Void)? = nil) {}
    func createCustomPlaylist(name: String) {}
    func deleteCustomPlaylist(id: UUID) {}
    func renameCustomPlaylist(id: UUID, newName: String) {}
    func addSongToCustomPlaylist(playlistID: UUID, songID: UInt64) {}
    func generateCover(for playlistID: UUID) {}
    func togglePlayPause() {}
    func playNext() {}
    func playPrevious() {}
    func seek(to time: Double) {}
    func setupRemoteCommands() {}
}

#endif
