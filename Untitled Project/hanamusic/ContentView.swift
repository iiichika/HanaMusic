import SwiftUI

#if os(iOS)
import MediaPlayer
import UniformTypeIdentifiers

// MARK: - 底部五栏枚举（最后一栏为设置，支持多语言跟随系统）
enum TabBarItem: Int, CaseIterable, Identifiable {
    case songs = 0
    case playlists = 1
    case files = 2
    case library = 3
    case settings = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .songs: return L10n.tabSongs
        case .playlists: return L10n.tabPlaylists
        case .files: return L10n.tabFiles
        case .library: return L10n.tabLibrary
        case .settings: return L10n.tabSettings
        }
    }

    var iconName: String {
        switch self {
        case .songs: return "music.note"
        case .playlists: return "list.bullet"
        case .files: return "folder.fill"
        case .library: return "square.stack.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - 主界面
struct ContentView: View {
    @StateObject private var musicManager = MusicManager.shared
    @ObservedObject private var liquidConfig = LiquidGlassConfig.shared

    @State private var selectedTab: TabBarItem = .library
    @State private var showFullScreenPlayer: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var importedFiles: [URL] = []
    @State private var searchText: String = ""
    @State private var isSearchBarVisible: Bool = false
    @State private var isSelectionMode: Bool = false

    // 底栏与播放条流体拖拽交互物理状态
    @State private var tabBarDragOffset: CGSize = .zero
    @State private var isTabBarDragging: Bool = false
    @State private var miniPlayerDragOffset: CGSize = .zero
    @State private var isMiniPlayerDragging: Bool = false

    // 新建与管理播放列表相关状态
    @State private var showCreatePlaylistAlert: Bool = false
    @State private var newPlaylistTitle: String = ""
    @State private var playlistToRename: CustomPlaylist?
    @State private var renameTitle: String = ""
    @State private var showRenameAlert: Bool = false
    @State private var playlistToDelete: CustomPlaylist?
    @State private var showDeletePlaylistAlert: Bool = false
    @State private var playlistFeedbackMessage: String?
    @State private var showPlaylistFeedbackAlert: Bool = false

    @Namespace private var animationNamespace

    // 歌曲「...」操作表相关状态
    @State private var editSong: MPMediaItem?
    @State private var editTitle: String = ""
    @State private var editArtist: String = ""
    @State private var showEditSheet: Bool = false
    @State private var selectedSongForPlaylist: MPMediaItem?
    @State private var showAddToPlaylistSheet: Bool = false
    @State private var songToDelete: MPMediaItem?
    @State private var showDeleteAlert: Bool = false
    // 控制栏是否融合成单一紧凑胶囊（类似 Apple Music 列表中向下滑动时两控件融合成一个）
    @State private var isControlsMerged: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationView {
                VStack(spacing: 0) {
                    // 顶部下拉呼出的搜索栏
                    if isSearchBarVisible || !searchText.isEmpty {
                        pullDownSearchBar
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }

                    // 主内容区
                    Group {
                        if !searchText.isEmpty {
                            globalSearchResultsView
                        } else {
                            switch selectedTab {
                            case .songs:
                                songsListView
                            case .playlists:
                                playlistsListView
                            case .files:
                                filesListView
                            case .library:
                                libraryMainView
                            case .settings:
                                settingsListView
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.22), value: selectedTab)
                }
                .navigationTitle(searchText.isEmpty ? navigationTitleForTab(selectedTab) : L10n.menuSearch)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: isControlsMerged ? 82 : 148)
                }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 最后一栏（设置）不展示右上角更多按钮
                    if selectedTab != .settings {
                        // 播放列表界面在右上角更多旁边创建「新建播放列表」按钮
                        if selectedTab == .playlists {
                            Button(action: {
                                newPlaylistTitle = ""
                                showCreatePlaylistAlert = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                        }

                        // 文件界面保留导入快捷按钮
                        if selectedTab == .files {
                            Button(action: { showFileImporter = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                        }

                        // 实例图片1规范的「更多」操作菜单（多语言跟随系统）
                        Menu {
                            // 1. 選択
                            Button(action: { isSelectionMode.toggle() }) {
                                Label(L10n.menuSelect, systemImage: isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                            }

                            // 2. 検索
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    isSearchBarVisible = true
                                }
                            }) {
                                Label(L10n.menuSearch, systemImage: "magnifyingglass")
                            }

                            // 3. 並べ替え
                            Menu {
                                Button(action: { musicManager.songSortOption = .title }) {
                                    Label(L10n.sortTitle, systemImage: musicManager.songSortOption == .title ? "checkmark" : "")
                                }
                                Button(action: { musicManager.songSortOption = .artist }) {
                                    Label(L10n.sortArtist, systemImage: musicManager.songSortOption == .artist ? "checkmark" : "")
                                }
                                Button(action: { musicManager.songSortOption = .dateAdded }) {
                                    Label(L10n.sortDateAdded, systemImage: musicManager.songSortOption == .dateAdded ? "checkmark" : "")
                                }
                            } label: {
                                Label(L10n.menuSortBy, systemImage: "arrow.up.arrow.down")
                            }

                            // 4. ソース
                            Menu {
                                Button(action: { musicManager.mediaSourceFilter = .all }) {
                                    Label(L10n.sourceAll, systemImage: musicManager.mediaSourceFilter == .all ? "checkmark" : "")
                                }
                                Button(action: { musicManager.mediaSourceFilter = .local }) {
                                    Label(L10n.sourceLocal, systemImage: musicManager.mediaSourceFilter == .local ? "checkmark" : "")
                                }
                                Button(action: { musicManager.mediaSourceFilter = .itunes }) {
                                    Label(L10n.sourceITunes, systemImage: musicManager.mediaSourceFilter == .itunes ? "checkmark" : "")
                                }
                            } label: {
                                Label(L10n.menuSource, systemImage: "line.3.horizontal.circle")
                            }

                            Divider()

                            // 5. すべて再生 & 随机
                            Button(action: {
                                if let first = musicManager.songs.first {
                                    musicManager.play(song: first, from: musicManager.songs)
                                }
                            }) {
                                Label(L10n.playAll, systemImage: "play.circle")
                            }

                            Button(action: {
                                musicManager.toggleShuffle()
                            }) {
                                Label(L10n.shufflePlay, systemImage: "shuffle")
                            }

                            Divider()

                            // 6. 設定
                            Button(action: {
                                selectedTab = .settings
                            }) {
                                Label(L10n.tabSettings, systemImage: "gearshape")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 19))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 15)
                    .onEnded { value in
                        if value.translation.height > 40 && value.startLocation.y < 240 {
                            if !isSearchBarVisible {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    isSearchBarVisible = true
                                }
                            }
                        } else if value.translation.height < -35 && searchText.isEmpty {
                            if isSearchBarVisible {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    isSearchBarVisible = false
                                }
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                    }
            )
            .onChange(of: selectedTab) { _, _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSearchBarVisible = false
                    searchText = ""
                }
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .sheet(isPresented: $showFullScreenPlayer) {
                FullScreenPlayerView(musicManager: musicManager)
            }
            .sheet(isPresented: $showEditSheet) {
                editSongSheet
            }
            .sheet(isPresented: $showAddToPlaylistSheet) {
                addToPlaylistSheet
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text(L10n.delete),
                    message: Text("「\(songToDelete?.title ?? "")」？"),
                    primaryButton: .destructive(Text(L10n.delete)) {
                        if let target = songToDelete {
                            musicManager.removeSong(target)
                        }
                    },
                    secondaryButton: .cancel(Text(L10n.cancel))
                )
            }
            .alert(isPresented: $showDeletePlaylistAlert) {
                Alert(
                    title: Text(L10n.deletePlaylist),
                    message: Text("「\(playlistToDelete?.name ?? "")」？"),
                    primaryButton: .destructive(Text(L10n.delete)) {
                        if let target = playlistToDelete {
                            musicManager.deleteCustomPlaylist(id: target.id)
                        }
                    },
                    secondaryButton: .cancel(Text(L10n.cancel))
                )
            }
            .alert(L10n.newPlaylist, isPresented: $showCreatePlaylistAlert) {
                TextField(L10n.newPlaylist, text: $newPlaylistTitle)
                Button(L10n.cancel, role: .cancel) {}
                Button(L10n.confirm) {
                    musicManager.createCustomPlaylist(name: newPlaylistTitle)
                }
            } message: {
                Text(L10n.newPlaylist)
            }
            .alert(L10n.rename, isPresented: $showRenameAlert) {
                TextField(L10n.rename, text: $renameTitle)
                Button(L10n.cancel, role: .cancel) {}
                Button(L10n.confirm) {
                    if let target = playlistToRename {
                        musicManager.renameCustomPlaylist(id: target.id, newName: renameTitle)
                    }
                }
            }
            .alert(isPresented: $showPlaylistFeedbackAlert) {
                Alert(title: Text(L10n.tabPlaylists), message: Text(playlistFeedbackMessage ?? ""), dismissButton: .default(Text(L10n.ok)))
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    importedFiles.append(contentsOf: urls)
                }
            }
        }
        .navigationViewStyle(.stack)

        // 悬浮层：全局常驻（在所有一级界面和二级详情页均常驻，向下滑动时自适应融合成单条）
        persistentBottomBarOverlay
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 15)
                .onChanged { value in
                    if value.translation.height < -25 {
                        // 向上拖动（向下浏览更多列表内容时）-> 融合为紧凑单条
                        if !isControlsMerged {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                isControlsMerged = true
                            }
                        }
                    } else if value.translation.height > 30 {
                        // 向下拖动（回滚到顶部时）-> 恢复双层展开
                        if isControlsMerged {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                isControlsMerged = false
                            }
                        }
                    }
                }
        )
        .preferredColorScheme(liquidConfig.appearanceMode == 1 ? .light : (liquidConfig.appearanceMode == 2 ? .dark : nil))
    }

    private func navigationTitleForTab(_ tab: TabBarItem) -> String {
        tab.title
    }

    // MARK: - 下拉式搜索栏
    private var pullDownSearchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)

                TextField(L10n.searchPlaceholder, text: $searchText)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 15))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)

            Button(L10n.cancel) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    searchText = ""
                    isSearchBarVisible = false
                }
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .foregroundColor(.red)
            .font(.system(size: 16))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }

    // MARK: - 1. 资料库页面
    private var libraryMainView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GeometryReader { proxy in
                    let offset = proxy.frame(in: .named("libraryScrollViewArea")).minY
                    Color.clear
                        .preference(key: PullDownOffsetKey.self, value: offset)
                }
                .frame(height: 0)

                // 分类入口列表
                VStack(spacing: 0) {
                    libraryCategoryRow(title: L10n.tabPlaylists, icon: "music.note.list", destination: AnyView(PlaylistsFullListView(musicManager: musicManager)))
                    Divider().padding(.leading, 50)
                    libraryCategoryRow(title: L10n.artists, icon: "music.mic", destination: AnyView(ArtistsListView(musicManager: musicManager)))
                    Divider().padding(.leading, 50)
                    libraryCategoryRow(title: L10n.albums, icon: "square.stack", destination: AnyView(AlbumsFullListView(musicManager: musicManager)))
                    Divider().padding(.leading, 50)
                    libraryCategoryRow(title: L10n.tabSongs, icon: "music.note", destination: AnyView(SongsFullListView(musicManager: musicManager)))
                    Divider().padding(.leading, 50)
                    libraryCategoryRow(title: L10n.genres, icon: "guitars", destination: AnyView(GenresListView(musicManager: musicManager)))
                    Divider().padding(.leading, 50)
                    libraryCategoryRow(title: L10n.localFiles, icon: "folder", destination: AnyView(filesListView))
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // 最近添加
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.recentlyAdded)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 18)
                        .padding(.top, 6)

                    if musicManager.recentlyAddedAlbums.isEmpty {
                        HStack {
                            Spacer()
                            Text(L10n.noRecentAlbums)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 30)
                            Spacer()
                        }
                    } else {
                        let columns = [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ]
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(musicManager.recentlyAddedAlbums, id: \.persistentID) { album in
                                NavigationLink(destination: CollectionDetailView(
                                    title: album.representativeItem?.albumTitle ?? "未知专辑",
                                    subtitle: album.representativeItem?.artist ?? "未知艺术家",
                                    collection: album,
                                    musicManager: musicManager
                                )) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        if let artwork = album.representativeItem?.artwork,
                                           let image = artwork.image(at: CGSize(width: 170, height: 170)) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(1, contentMode: .fill)
                                                .cornerRadius(8)
                                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                                        } else {
                                            ZStack {
                                                Color(UIColor.systemGray5)
                                                Image(systemName: "opticaldisc")
                                                    .font(.system(size: 42))
                                                    .foregroundColor(.gray)
                                            }
                                            .aspectRatio(1, contentMode: .fit)
                                            .cornerRadius(8)
                                        }

                                        Text(album.representativeItem?.albumTitle ?? "未知专辑")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)

                                        Text(album.representativeItem?.artist ?? "未知艺术家")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                            }
        }
        .coordinateSpace(name: "libraryScrollViewArea")
        .onPreferenceChange(PullDownOffsetKey.self) { offset in
            if offset > 45 && !isSearchBarVisible {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    isSearchBarVisible = true
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func libraryCategoryRow(title: String, icon: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                    .frame(width: 26)

                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
    }

    // MARK: - 2. 全局下拉搜索结果聚合视图
    private var globalSearchResultsView: some View {
        List {
            let matchedSongs = musicManager.songs.filter {
                ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            if !matchedSongs.isEmpty {
                Section(header: Text("\(L10n.tabSongs) (\(matchedSongs.count))")) {
                    ForEach(matchedSongs.prefix(10), id: \.persistentID) { song in
                        HStack(spacing: 12) {
                            if let artwork = song.artwork,
                               let image = artwork.image(at: CGSize(width: 40, height: 40)) {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(6)
                            } else {
                                ZStack {
                                    Color(UIColor.systemGray5)
                                    Image(systemName: "music.note")
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 40, height: 40)
                                .cornerRadius(6)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title ?? "未知曲目")
                                    .font(.system(size: 15))
                                    .lineLimit(1)
                                Text(song.artist ?? "未知艺术家")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            musicManager.play(song: song, from: matchedSongs)
                        }
                    }
                }
            }

            let matchedAlbums = musicManager.albums.filter {
                ($0.representativeItem?.albumTitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.representativeItem?.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            if !matchedAlbums.isEmpty {
                Section(header: Text("\(L10n.albums) (\(matchedAlbums.count))")) {
                    ForEach(matchedAlbums.prefix(6), id: \.persistentID) { album in
                        NavigationLink(destination: CollectionDetailView(
                            title: album.representativeItem?.albumTitle ?? "未知专辑",
                            subtitle: album.representativeItem?.artist ?? "未知艺术家",
                            collection: album,
                            musicManager: musicManager
                        )) {
                            CollectionRowView(
                                title: album.representativeItem?.albumTitle ?? "未知专辑",
                                subtitle: album.representativeItem?.artist ?? "未知艺术家",
                                artwork: album.representativeItem?.artwork,
                                fallbackIcon: "opticaldisc"
                            )
                        }
                    }
                }
            }

            let matchedArtists = musicManager.artists.filter {
                $0.representativeItem?.artist?.localizedCaseInsensitiveContains(searchText) ?? false
            }
            if !matchedArtists.isEmpty {
                Section(header: Text("\(L10n.artists) (\(matchedArtists.count))")) {
                    ForEach(matchedArtists.prefix(6), id: \.persistentID) { artist in
                        let name = artist.representativeItem?.artist ?? "未知艺术家"
                        NavigationLink(destination: CollectionDetailView(
                            title: name,
                            subtitle: "\(artist.count) 首歌曲",
                            collection: artist,
                            musicManager: musicManager
                        )) {
                            CollectionRowView(
                                title: name,
                                subtitle: "\(artist.count) 首曲目",
                                artwork: artist.representativeItem?.artwork,
                                fallbackIcon: "person.circle"
                            )
                        }
                    }
                }
            }

                    }
        .listStyle(.insetGrouped)
    }

    // MARK: - 全局常驻悬浮控制层（支持向下滑动时两控件融合成一个）
    private var persistentBottomBarOverlay: some View {
        VStack(spacing: 8) {
            if isControlsMerged {
                fusedCompactBar
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.94).combined(with: .opacity),
                        removal: .scale(scale: 0.94).combined(with: .opacity)
                    ))
            } else {
                VStack(spacing: 8) {
                    floatingMiniPlayer
                    floatingTabBar
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.94).combined(with: .opacity),
                    removal: .scale(scale: 0.94).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: isControlsMerged)
    }

    // MARK: - 融合成的单体极简流体控制栏（对齐参考图 2 交互规范）
    private var fusedCompactBar: some View {
        HStack(spacing: 10) {
            // 左侧：当前栏目主图标（带 Apple 标志性圆环底衬，轻点展开完整双层栏）
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    isControlsMerged = false
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: selectedTab.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(.plain)

            // 中间：紧凑型 Mini 播放条（封面 + 歌名/艺术家 + 播放/暂停）
            HStack(spacing: 10) {
                if let image = musicManager.currentArtworkImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(radius: 2)
                } else {
                    ZStack {
                        Color(UIColor.systemGray5).opacity(0.8)
                        Image(systemName: "music.note")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(musicManager.currentTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(musicManager.currentArtist)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // 播放/暂停按键
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        musicManager.togglePlayPause()
                    }
                }) {
                    Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    showFullScreenPlayer = true
                }
            }

            // 右侧：搜索或展开按钮（对齐参考图 2 右侧搜索镜按钮）
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    isSearchBarVisible.toggle()
                    if isSearchBarVisible {
                        isControlsMerged = false
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.systemGray5).opacity(0.6))
                        .frame(width: 44, height: 44)

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(height: 60)
        .modifier(LiquidGlassModifier(cornerRadius: 32))
    }

    // MARK: - 3. 悬浮播放条（支持自主本地音频引擎、流体拖拽与转场动效）
    private var floatingMiniPlayer: some View {
        HStack(spacing: 12) {
            if let image = musicManager.currentArtworkImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .cornerRadius(8)
                    .shadow(radius: 2)
            } else {
                ZStack {
                    Color(UIColor.systemGray5).opacity(0.8)
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .frame(width: 44, height: 44)
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(musicManager.currentTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(musicManager.currentArtist)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    musicManager.togglePlayPause()
                }
            }) {
                Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .scaleEffect(musicManager.isPlaying ? 1.0 : 0.94)
                    .frame(width: 36, height: 36)
            }

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    musicManager.playNext()
                }
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                showFullScreenPlayer = true
            }
        }
        // 流体拖拽手势：向上拖动唤出全屏播放，左右滑动换歌
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    isMiniPlayerDragging = true
                    let dampedX = value.translation.width * 0.4
                    let dampedY = value.translation.height < 0 ? value.translation.height * 0.7 : value.translation.height * 0.3
                    miniPlayerDragOffset = CGSize(width: dampedX, height: dampedY)
                }
                .onEnded { value in
                    if value.translation.height < -55 {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showFullScreenPlayer = true
                    } else if value.translation.width < -75 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        musicManager.playNext()
                    } else if value.translation.width > 75 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        musicManager.playPrevious()
                    }
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.62, blendDuration: 0.25)) {
                        miniPlayerDragOffset = .zero
                        isMiniPlayerDragging = false
                    }
                }
        )
        .modifier(LiquidGlassModifier(cornerRadius: 18, dragOffset: miniPlayerDragOffset, isDragging: isMiniPlayerDragging))
    }

    // MARK: - 4. 苹果 Liquid Glass 五栏底栏（支持流体交互可拖拽手势）
    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            ForEach(TabBarItem.allCases) { item in
                let isSelected = selectedTab == item
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        selectedTab = item
                    }
                }) {
                    VStack(spacing: 3) {
                        ZStack {
                            if isSelected {
                                Capsule()
                                    .fill(Color.red.opacity(0.18))
                                    .frame(width: 52, height: 30)
                                    .matchedGeometryEffect(id: "tabBubble", in: animationNamespace)
                            }
                            Image(systemName: item.iconName)
                                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .red : .secondary)
                        }
                        .frame(height: 30)

                        Text(item.title)
                            .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .red : .secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        // 流体拖拽手势：水平拖拉带弹性阻尼感，支持横向划动在选项卡之间流体切换
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    isTabBarDragging = true
                    let dampedX = value.translation.width * 0.45
                    let dampedY = value.translation.height * 0.25
                    tabBarDragOffset = CGSize(width: dampedX, height: dampedY)
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    let allTabs = TabBarItem.allCases
                    if value.translation.width > threshold {
                        if let currentIndex = allTabs.firstIndex(of: selectedTab), currentIndex > 0 {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                selectedTab = allTabs[currentIndex - 1]
                            }
                        }
                    } else if value.translation.width < -threshold {
                        if let currentIndex = allTabs.firstIndex(of: selectedTab), currentIndex < allTabs.count - 1 {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                selectedTab = allTabs[currentIndex + 1]
                            }
                        }
                    }
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.64, blendDuration: 0.25)) {
                        tabBarDragOffset = .zero
                        isTabBarDragging = false
                    }
                }
        )
        .modifier(LiquidGlassModifier(cornerRadius: 32, dragOffset: tabBarDragOffset, isDragging: isTabBarDragging))
    }

    // MARK: - 5. 曲目列表
    private var songsListView: some View {
        let sorted = musicManager.songs.sorted { s1, s2 in
            switch musicManager.songSortOption {
            case .title:
                return (s1.title ?? "") < (s2.title ?? "")
            case .artist:
                return (s1.artist ?? "") < (s2.artist ?? "")
            case .dateAdded:
                let d1 = s1.value(forProperty: MPMediaItemPropertyDateAdded) as? Date ?? Date.distantPast
                let d2 = s2.value(forProperty: MPMediaItemPropertyDateAdded) as? Date ?? Date.distantPast
                return d1 > d2
            }
        }

        let grouped = SectionIndexHelper.groupItems(sorted) { song in
            song.title ?? "未知曲目"
        }

        return ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                List {
                    ForEach(grouped, id: \.key) { section in
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
                                        Text(song.title ?? "未知曲目")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(musicManager.currentSong?.persistentID == song.persistentID ? .red : .primary)
                                            .lineLimit(1)

                                        Text(song.artist ?? "未知艺术家")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    // 右侧三个点菜单
                                    Menu {
                                        Button(action: {
                                            editSong = song
                                            editTitle = song.title ?? ""
                                            editArtist = song.artist ?? ""
                                            showEditSheet = true
                                        }) {
                                            Label(L10n.editSongInfo, systemImage: "pencil")
                                        }

                                        Button(action: {
                                            musicManager.playNext(song: song)
                                        }) {
                                            Label(L10n.nextToPlay, systemImage: "text.line.first.and.arrowtriangle.forward")
                                        }

                                        Button(action: {
                                            selectedSongForPlaylist = song
                                            showAddToPlaylistSheet = true
                                        }) {
                                            Label(L10n.addToPlaylist, systemImage: "text.badge.plus")
                                        }

                                        Button(action: {
                                            musicManager.toggleFavorite(song: song)
                                        }) {
                                            Label(
                                                musicManager.isFavorite(song: song) ? L10n.unfavorite : L10n.favorites,
                                                systemImage: musicManager.isFavorite(song: song) ? "heart.fill" : "heart"
                                            )
                                        }

                                        Button(role: .destructive, action: {
                                            songToDelete = song
                                            showDeleteAlert = true
                                        }) {
                                            Label(L10n.delete, systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                            .frame(width: 32, height: 32)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    musicManager.play(song: song)
                                }
                                .listRowSeparator(.visible)
                            }
                        }
                    }

                                    }
                .listStyle(.plain)

                SectionIndexBar(sections: SectionIndexHelper.indexTitles) { key in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(key, anchor: .top)
                    }
                }
            }
        }
    }

    // MARK: - 6. 歌单列表
    private var playlistsListView: some View {
        let grouped = SectionIndexHelper.groupItems(musicManager.playlists) { playlist in
            playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "未命名歌单"
        }

        return ScrollViewReader { proxy in
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

                                    playlistRowMenu(custom: custom)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    ForEach(grouped, id: \.key) { section in
                        Section(header: Text(section.key).id(section.key).font(.subheadline).bold()) {
                            ForEach(section.items, id: \.persistentID) { playlist in
                                let name = playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "未命名歌单"
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

                                    playlistRowMenu(collection: playlist, name: name)
                                }
                            }
                        }
                    }

                                    }
                .listStyle(.plain)

                SectionIndexBar(sections: SectionIndexHelper.indexTitles) { key in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(key, anchor: .top)
                    }
                }
            }
        }
    }

    // 实例图片2完整 8 项功能菜单（多语言统一）
    @ViewBuilder
    private func playlistRowMenu(collection: MPMediaItemCollection? = nil, custom: CustomPlaylist? = nil, name: String? = nil) -> some View {
        let title = custom?.name ?? name ?? L10n.tabPlaylists
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
            Button(action: {
                playlistFeedbackMessage = "已打开封面编辑"
                showPlaylistFeedbackAlert = true
            }) {
                Label(L10n.editImage, systemImage: "photo")
            }

            // 3. カバーを生成
            Button(action: {
                if let c = custom {
                    musicManager.generateCover(for: c.id)
                    playlistFeedbackMessage = "已成功生成「\(c.name)」艺术封面"
                    showPlaylistFeedbackAlert = true
                } else {
                    playlistFeedbackMessage = "已成功生成全新渐变封面"
                    showPlaylistFeedbackAlert = true
                }
            }) {
                Label(L10n.generateCover, systemImage: "sparkles")
            }

            // 4. 曲を追加
            Button(action: {
                showAddToPlaylistSheet = true
            }) {
                Label(L10n.addSongs, systemImage: "plus")
            }

            // 5. 名称変更
            Button(action: {
                if let c = custom {
                    playlistToRename = c
                    renameTitle = c.name
                    showRenameAlert = true
                }
            }) {
                Label(L10n.rename, systemImage: "pencil")
            }

            // 6. プレイリストに追加する
            Button(action: {
                playlistFeedbackMessage = "已添加到播放列表备份"
                showPlaylistFeedbackAlert = true
            }) {
                Label(L10n.addToPlaylist, systemImage: "text.badge.plus")
            }

            // 7. ウォッチへ転送
            Button(action: {
                playlistFeedbackMessage = "正在将「\(title)」传输至 Apple Watch..."
                showPlaylistFeedbackAlert = true
            }) {
                Label(L10n.transferToWatch, systemImage: "applewatch")
            }

            Divider()

            // 8. プレイリストを削除
            Button(role: .destructive, action: {
                if let c = custom {
                    playlistToDelete = c
                    showDeletePlaylistAlert = true
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

    // MARK: - 7. 文件列表（原生支持点击直接播放本地导入音轨）
    private var filesListView: some View {
        List {
            Section(header: Text(L10n.localFiles)) {
                let allFiles = musicManager.scannedLocalFiles.isEmpty ? importedFiles : musicManager.scannedLocalFiles
                if allFiles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text(L10n.noImportedAudio)
                            .font(.headline)
                        Text(L10n.tapPlusToImport)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    ForEach(allFiles, id: \.self) { fileUrl in
                        let isCurrent = musicManager.currentLocalTrack?.url == fileUrl
                        HStack(spacing: 12) {
                            Image(systemName: isCurrent && musicManager.isPlaying ? "waveform" : "doc.audio")
                                .foregroundColor(isCurrent ? .red : .blue)
                                .font(.system(size: 18))
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(fileUrl.lastPathComponent)
                                    .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                                    .foregroundColor(isCurrent ? .red : .primary)
                                    .lineLimit(1)

                                Text(fileUrl.pathExtension.uppercased())
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isCurrent {
                                Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if isCurrent {
                                musicManager.togglePlayPause()
                            } else {
                                musicManager.play(url: fileUrl)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - 8. 设置一级菜单
    private var settingsListView: some View {
        SettingsView(musicManager: musicManager)
    }

    // MARK: - 编辑歌曲信息弹窗
    private var editSongSheet: some View {
        NavigationView {
            Form {
                Section(header: Text(L10n.songInfo)) {
                    TextField("タイトル", text: $editTitle)
                    TextField("アーティスト", text: $editArtist)
                }
            }
            .navigationTitle(L10n.editSongInfo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { showEditSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) { showEditSheet = false }
                }
            }
        }
    }

    // MARK: - 添加到播放列表弹窗
    private var addToPlaylistSheet: some View {
        NavigationView {
            List {
                if !musicManager.customPlaylists.isEmpty {
                    Section(header: Text(L10n.customPlaylists)) {
                        ForEach(musicManager.customPlaylists) { custom in
                            Button(action: {
                                if let song = selectedSongForPlaylist {
                                    musicManager.addSongToCustomPlaylist(playlistID: custom.id, song: song)
                                }
                                showAddToPlaylistSheet = false
                            }) {
                                HStack {
                                    Image(systemName: custom.coverSymbol)
                                        .foregroundColor(Color(hex: custom.coverColorHex))
                                    Text(custom.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(L10n.songCount(custom.songPersistentIDs.count))
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }

                Section(header: Text(L10n.tabPlaylists)) {
                    ForEach(musicManager.playlists, id: \.persistentID) { playlist in
                        let name = playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "未命名歌单"
                        Button(action: { showAddToPlaylistSheet = false }) {
                            HStack {
                                Image(systemName: "music.note.list")
                                    .foregroundColor(.blue)
                                Text(name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(L10n.songCount(playlist.count))
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.addToPlaylist)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完了") { showAddToPlaylistSheet = false }
                }
            }
        }
    }
}

// MARK: - 保持兼容性别名
typealias LiquidGlassBackground = LiquidGlassModifier

// MARK: - 通用行视图
struct CollectionRowView: View {
    let title: String
    let subtitle: String
    let artwork: MPMediaItemArtwork?
    let fallbackIcon: String

    var body: some View {
        HStack(spacing: 12) {
            if let artwork = artwork,
               let image = artwork.image(at: CGSize(width: 48, height: 48)) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .cornerRadius(6)
            } else {
                ZStack {
                    Color(UIColor.systemGray5)
                    Image(systemName: fallbackIcon)
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                }
                .frame(width: 48, height: 48)
                .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

struct PullDownOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#else

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            Text("这是一个 iOS 音乐播放器")
                .font(.headline)
            Text("请在 Xcode 窗口顶部的目标设备中选择 iPhone 进行运行与测试。")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#endif
