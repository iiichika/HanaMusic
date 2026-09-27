import Foundation
import SwiftUI

// MARK: - 多语言国际化核心助手（完全跟随 iOS 系统语言设置，无须应用内手动切换）
enum AppLanguage {
    case japanese
    case chinese
    case english

    static var current: AppLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "zh"
        if preferred.starts(with: "ja") {
            return .japanese
        } else if preferred.starts(with: "zh") {
            return .chinese
        } else {
            return .english
        }
    }
}

struct L10n {
    // MARK: - 底栏导航
    static var tabSongs: String {
        switch AppLanguage.current {
        case .japanese: return "曲"
        case .chinese: return "曲目"
        case .english: return "Songs"
        }
    }

    static var tabPlaylists: String {
        switch AppLanguage.current {
        case .japanese: return "プレイリスト"
        case .chinese: return "播放列表"
        case .english: return "Playlists"
        }
    }

    static var tabFiles: String {
        switch AppLanguage.current {
        case .japanese: return "ファイル"
        case .chinese: return "文件"
        case .english: return "Files"
        }
    }

    static var tabLibrary: String {
        switch AppLanguage.current {
        case .japanese: return "ライブラリ"
        case .chinese: return "资料库"
        case .english: return "Library"
        }
    }

    static var tabSettings: String {
        switch AppLanguage.current {
        case .japanese: return "設定"
        case .chinese: return "设置"
        case .english: return "Settings"
        }
    }

    // MARK: - 图1 更多操作菜单
    static var menuSelect: String {
        switch AppLanguage.current {
        case .japanese: return "選択"
        case .chinese: return "选择"
        case .english: return "Select"
        }
    }

    static var menuSearch: String {
        switch AppLanguage.current {
        case .japanese: return "検索"
        case .chinese: return "搜索"
        case .english: return "Search"
        }
    }

    static var menuSortBy: String {
        switch AppLanguage.current {
        case .japanese: return "並べ替え"
        case .chinese: return "排序方式"
        case .english: return "Sort By"
        }
    }

    static var sortTitle: String {
        switch AppLanguage.current {
        case .japanese: return "タイトル (按标题)"
        case .chinese: return "按标题"
        case .english: return "Title"
        }
    }

    static var sortArtist: String {
        switch AppLanguage.current {
        case .japanese: return "アーティスト (按艺术家)"
        case .chinese: return "按艺术家"
        case .english: return "Artist"
        }
    }

    static var sortDateAdded: String {
        switch AppLanguage.current {
        case .japanese: return "追加日 (按添加时间)"
        case .chinese: return "按添加时间"
        case .english: return "Date Added"
        }
    }

    static var menuSource: String {
        switch AppLanguage.current {
        case .japanese: return "ソース"
        case .chinese: return "音源"
        case .english: return "Source"
        }
    }

    static var sourceAll: String {
        switch AppLanguage.current {
        case .japanese: return "すべて (全部)"
        case .chinese: return "全部音源"
        case .english: return "All"
        }
    }

    static var sourceLocal: String {
        switch AppLanguage.current {
        case .japanese: return "ローカル (本地文件)"
        case .chinese: return "本地文件"
        case .english: return "Local Files"
        }
    }

    static var sourceITunes: String {
        switch AppLanguage.current {
        case .japanese: return "iTunes ライブラリ"
        case .chinese: return "iTunes 媒体库"
        case .english: return "iTunes Library"
        }
    }

    static var playAll: String {
        switch AppLanguage.current {
        case .japanese: return "すべて再生"
        case .chinese: return "播放全部"
        case .english: return "Play All"
        }
    }

    static var shufflePlay: String {
        switch AppLanguage.current {
        case .japanese: return "シャッフル再生"
        case .chinese: return "随机播放"
        case .english: return "Shuffle Play"
        }
    }

    // MARK: - 图2 歌单8大操作菜单
    static var editImage: String {
        switch AppLanguage.current {
        case .japanese: return "画像を編集"
        case .chinese: return "编辑封面"
        case .english: return "Edit Image"
        }
    }

    static var generateCover: String {
        switch AppLanguage.current {
        case .japanese: return "カバーを生成"
        case .chinese: return "生成艺术封面"
        case .english: return "Generate Cover"
        }
    }

    static var addSongs: String {
        switch AppLanguage.current {
        case .japanese: return "曲を追加"
        case .chinese: return "添加曲目"
        case .english: return "Add Songs"
        }
    }

    static var rename: String {
        switch AppLanguage.current {
        case .japanese: return "名称変更"
        case .chinese: return "重命名"
        case .english: return "Rename"
        }
    }

    static var addToPlaylist: String {
        switch AppLanguage.current {
        case .japanese: return "プレイリストに追加する"
        case .chinese: return "添加到播放列表"
        case .english: return "Add to Playlist"
        }
    }

    static var transferToWatch: String {
        switch AppLanguage.current {
        case .japanese: return "ウォッチへ転送"
        case .chinese: return "传输至 Apple Watch"
        case .english: return "Transfer to Watch"
        }
    }

    static var deletePlaylist: String {
        switch AppLanguage.current {
        case .japanese: return "プレイリストを削除"
        case .chinese: return "删除播放列表"
        case .english: return "Delete Playlist"
        }
    }

    // MARK: - 资料库与分类
    static var recentlyAdded: String {
        switch AppLanguage.current {
        case .japanese: return "最近追加した項目"
        case .chinese: return "最近添加"
        case .english: return "Recently Added"
        }
    }

    static var artists: String {
        switch AppLanguage.current {
        case .japanese: return "アーティスト"
        case .chinese: return "艺术家"
        case .english: return "Artists"
        }
    }

    static var albums: String {
        switch AppLanguage.current {
        case .japanese: return "アルバム"
        case .chinese: return "专辑"
        case .english: return "Albums"
        }
    }

    static var genres: String {
        switch AppLanguage.current {
        case .japanese: return "ジャンル"
        case .chinese: return "流派"
        case .english: return "Genres"
        }
    }

    static var localFiles: String {
        switch AppLanguage.current {
        case .japanese: return "ローカルファイル"
        case .chinese: return "本地文件"
        case .english: return "Local Files"
        }
    }

    static var customPlaylists: String {
        switch AppLanguage.current {
        case .japanese: return "マイプレイリスト"
        case .chinese: return "自建播放列表"
        case .english: return "My Playlists"
        }
    }

    static var newPlaylist: String {
        switch AppLanguage.current {
        case .japanese: return "新規プレイリスト"
        case .chinese: return "新建播放列表"
        case .english: return "New Playlist"
        }
    }

    // MARK: - 播放条与状态
    static var notPlaying: String {
        switch AppLanguage.current {
        case .japanese: return "再生されていません"
        case .chinese: return "未在播放"
        case .english: return "Not Playing"
        }
    }

    static var tapToPlay: String {
        switch AppLanguage.current {
        case .japanese: return "タップして曲を再生"
        case .chinese: return "点击曲目开始播放"
        case .english: return "Tap to play"
        }
    }

    static var nowPlaying: String {
        switch AppLanguage.current {
        case .japanese: return "再生中"
        case .chinese: return "正在播放"
        case .english: return "Now Playing"
        }
    }

    static var listenNow: String {
        switch AppLanguage.current {
        case .japanese: return "今すぐ聴く"
        case .chinese: return "即刻聆听"
        case .english: return "Listen Now"
        }
    }

    static var favorites: String {
        switch AppLanguage.current {
        case .japanese: return "お気に入り"
        case .chinese: return "喜爱曲目"
        case .english: return "Favorites"
        }
    }

    // MARK: - 交互与按钮
    static var cancel: String {
        switch AppLanguage.current {
        case .japanese: return "キャンセル"
        case .chinese: return "取消"
        case .english: return "Cancel"
        }
    }

    static var confirm: String {
        switch AppLanguage.current {
        case .japanese: return "確認"
        case .chinese: return "确认"
        case .english: return "Confirm"
        }
    }

    static var delete: String {
        switch AppLanguage.current {
        case .japanese: return "削除"
        case .chinese: return "删除"
        case .english: return "Delete"
        }
    }

    static var ok: String {
        switch AppLanguage.current {
        case .japanese: return "OK"
        case .chinese: return "好"
        case .english: return "OK"
        }
    }

    static var save: String {
        switch AppLanguage.current {
        case .japanese: return "保存"
        case .chinese: return "保存"
        case .english: return "Save"
        }
    }

    static var searchPlaceholder: String {
        switch AppLanguage.current {
        case .japanese: return "曲、アーティスト、アルバムを検索"
        case .chinese: return "搜索歌曲、专辑、艺人或歌单"
        case .english: return "Search songs, artists, albums"
        }
    }

    // MARK: - 辅助计量单位
    static func songCount(_ count: Int) -> String {
        switch AppLanguage.current {
        case .japanese: return "\(count) 曲"
        case .chinese: return "\(count) 首歌曲"
        case .english: return count == 1 ? "1 song" : "\(count) songs"
        }
    }

    static func albumCount(_ count: Int) -> String {
        switch AppLanguage.current {
        case .japanese: return "\(count) 枚のアルバム"
        case .chinese: return "\(count) 张专辑"
        case .english: return count == 1 ? "1 album" : "\(count) albums"
        }
    }

    static func artistCount(_ count: Int) -> String {
        switch AppLanguage.current {
        case .japanese: return "\(count) 人のアーティスト"
        case .chinese: return "\(count) 位艺人"
        case .english: return count == 1 ? "1 artist" : "\(count) artists"
        }
    }

    static func playlistCount(_ count: Int) -> String {
        switch AppLanguage.current {
        case .japanese: return "\(count) 個のプレイリスト"
        case .chinese: return "\(count) 个歌单"
        case .english: return count == 1 ? "1 playlist" : "\(count) playlists"
        }
    }

    // MARK: - Liquid Glass 与外观
    static var liquidGlassEffect: String {
        switch AppLanguage.current {
        case .japanese: return "リキッドグラス効果"
        case .chinese: return "Liquid Glass 流体毛玻璃效果"
        case .english: return "Liquid Glass Effect"
        }
    }

    static var appearanceMode: String {
        switch AppLanguage.current {
        case .japanese: return "外観モード"
        case .chinese: return "外观模式"
        case .english: return "Appearance Mode"
        }
    }

    static var appearanceSystem: String {
        switch AppLanguage.current {
        case .japanese: return "システム"
        case .chinese: return "跟随系统"
        case .english: return "System"
        }
    }

    static var appearanceLight: String {
        switch AppLanguage.current {
        case .japanese: return "ライト"
        case .chinese: return "浅色"
        case .english: return "Light"
        }
    }

    static var appearanceDark: String {
        switch AppLanguage.current {
        case .japanese: return "ダーク"
        case .chinese: return "深色"
        case .english: return "Dark"
        }
    }

    static var glassIntensity: String {
        switch AppLanguage.current {
        case .japanese: return "グラス効果の強度"
        case .chinese: return "玻璃折射强度"
        case .english: return "Glass Intensity"
        }
    }

    static var glassLivePreview: String {
        switch AppLanguage.current {
        case .japanese: return "リアルタイムプレビュー"
        case .chinese: return "实时效果预览"
        case .english: return "Live Preview"
        }
    }

    static var glassPresetSubtle: String {
        switch AppLanguage.current {
        case .japanese: return "控えめ 40%"
        case .chinese: return "柔和 40%"
        case .english: return "Subtle 40%"
        }
    }

    static var glassPresetStandard: String {
        switch AppLanguage.current {
        case .japanese: return "標準 75%"
        case .chinese: return "标准 75%"
        case .english: return "Standard 75%"
        }
    }

    static var glassPresetVivid: String {
        switch AppLanguage.current {
        case .japanese: return "クリア 95%"
        case .chinese: return "通透 95%"
        case .english: return "Vivid 95%"
        }
    }

    static var glassResetDefault: String {
        switch AppLanguage.current {
        case .japanese: return "デフォルトに戻す"
        case .chinese: return "恢复默认"
        case .english: return "Reset"
        }
    }

    // MARK: - 设置界面 & 文件管理
    static var fileManagement: String {
        switch AppLanguage.current {
        case .japanese: return "ファイル管理"
        case .chinese: return "文件管理"
        case .english: return "File Management"
        }
    }

    static var wifiTransfer: String {
        switch AppLanguage.current {
        case .japanese: return "Wi-Fi 転送"
        case .chinese: return "Wi-Fi 传输"
        case .english: return "Wi-Fi Transfer"
        }
    }

    static var cableTransfer: String {
        switch AppLanguage.current {
        case .japanese: return "ケーブル転送"
        case .chinese: return "数据线传输"
        case .english: return "Cable Transfer"
        }
    }

    static var openFile: String {
        switch AppLanguage.current {
        case .japanese: return "ファイルを開く..."
        case .chinese: return "打开文件..."
        case .english: return "Open Files..."
        }
    }

    static var airDrop: String {
        switch AppLanguage.current {
        case .japanese: return "AirDrop (エアドロップ)"
        case .chinese: return "隔空投送 (AirDrop)"
        case .english: return "AirDrop"
        }
    }

    static var localScan: String {
        switch AppLanguage.current {
        case .japanese: return "ローカル音源スキャン"
        case .chinese: return "本地音频文件扫描"
        case .english: return "Scan Local Audio"
        }
    }

    static func discoveredLocalFiles(_ count: Int) -> String {
        switch AppLanguage.current {
        case .japanese: return "\(count) 個のローカル音源を検出"
        case .chinese: return "已发现 \(count) 个本地文件"
        case .english: return "\(count) local files discovered"
        }
    }

    static var syncITunes: String {
        switch AppLanguage.current {
        case .japanese: return "iTunes ライブラリと同期"
        case .chinese: return "同步 iTunes 音乐库"
        case .english: return "Sync iTunes Library"
        }
    }

    static func songsAndAlbumsCount(songs: Int, albums: Int) -> String {
        switch AppLanguage.current {
        case .japanese: return "\(songs) 曲 · \(albums) 枚のアルバム"
        case .chinese: return "\(songs) 首歌曲 · \(albums) 张专辑"
        case .english: return "\(songs) Songs · \(albums) Albums"
        }
    }

    static var storageManagement: String {
        switch AppLanguage.current {
        case .japanese: return "ストレージ管理"
        case .chinese: return "存储管理"
        case .english: return "Storage Management"
        }
    }

    static func usedStorageText(_ text: String) -> String {
        switch AppLanguage.current {
        case .japanese: return "使用済み \(text)"
        case .chinese: return "已用约 \(text)"
        case .english: return "Used \(text)"
        }
    }

    static var userGuide: String {
        switch AppLanguage.current {
        case .japanese: return "ユーザーガイド"
        case .chinese: return "用户指南"
        case .english: return "User Guide"
        }
    }

    static var playbackSettings: String {
        switch AppLanguage.current {
        case .japanese: return "再生設定"
        case .chinese: return "播放设置"
        case .english: return "Playback Settings"
        }
    }

    static var highQualityOutputActive: String {
        switch AppLanguage.current {
        case .japanese: return "ロスレス高音質出力中"
        case .chinese: return "高品质输出已开启"
        case .english: return "High Quality Output On"
        }
    }

    static var soundSettingsGuide: String {
        switch AppLanguage.current {
        case .japanese: return "サウンド設定ガイド"
        case .chinese: return "声音设置指南"
        case .english: return "Sound Settings Guide"
        }
    }

    static var carPlay: String {
        switch AppLanguage.current {
        case .japanese: return "CarPlay 車載"
        case .chinese: return "车载 CarPlay"
        case .english: return "CarPlay"
        }
    }

    static var carPlayReady: String {
        switch AppLanguage.current {
        case .japanese: return "Apple Music 構造対応済み"
        case .chinese: return "Apple Music 架构已就绪"
        case .english: return "Apple Music Ready"
        }
    }

    static var copyFilesInImport: String {
        switch AppLanguage.current {
        case .japanese: return "インポート時にファイルをコピー"
        case .chinese: return "导入时拷贝文件"
        case .english: return "Copy Files on Import"
        }
    }

    static var showAudioQualityInfo: String {
        switch AppLanguage.current {
        case .japanese: return "音質情報を表示"
        case .chinese: return "显示音质信息"
        case .english: return "Show Audio Quality Info"
        }
    }

    static var about: String {
        switch AppLanguage.current {
        case .japanese: return "情報"
        case .chinese: return "关于"
        case .english: return "About"
        }
    }

    static var aboutHanaMusic: String {
        switch AppLanguage.current {
        case .japanese: return "Hana Music について"
        case .chinese: return "关于 Hana Music"
        case .english: return "About Hana Music"
        }
    }

    static var followSystemSettings: String {
        switch AppLanguage.current {
        case .japanese: return "システム設定に追従"
        case .chinese: return "跟随系统设置"
        case .english: return "Following System"
        }
    }

    static var reduceTransparencyNote: String {
        switch AppLanguage.current {
        case .japanese: return "アクセシビリティ「透明度を下げる」が有効なため、高コントラスト素材に自動降格しました（Apple HIG 準拠）。"
        case .chinese: return "系统辅助功能「降低透明度」已开启，已自动降级为高对比度实体材质（符合 Apple HIG 规范）。"
        case .english: return "Accessibility 'Reduce Transparency' enabled. High contrast material applied per Apple HIG."
        }
    }

    static var systemMaterialsNote: String {
        switch AppLanguage.current {
        case .japanese: return "システムの表示設定と材質データを呼び出し、外観と視覚効果にリアルタイムで適応します。"
        case .chinese: return "已直接调用系统全局显示与材质折射数据，根据当前外观模式及系统视觉效果实时自适应。"
        case .english: return "Directly adapts to system visual parameters and appearance mode in real time."
        }
    }

    // MARK: - 弹窗 Sheets 详细多语言
    static var wifiTransferTitle: String {
        switch AppLanguage.current {
        case .japanese: return "Wi-Fi ローカル転送"
        case .chinese: return "Wi-Fi 局域网传输"
        case .english: return "Wi-Fi Local Transfer"
        }
    }

    static var wifiTransferDesc: String {
        switch AppLanguage.current {
        case .japanese: return "iPhone とパソコンを同じ Wi-Fi ネットワークに接続してください。\nPC のブラウザで以下のアドレスにアクセスして音源をアップロードできます："
        case .chinese: return "确保您的 iPhone 与电脑连接在同一个 Wi-Fi 网络下。\n在电脑浏览器访问下方地址即可无线上传音乐："
        case .english: return "Ensure your iPhone and computer are on the same Wi-Fi.\nVisit the address below in your computer browser to upload audio:"
        }
    }

    static var cableTransferTitle: String {
        switch AppLanguage.current {
        case .japanese: return "ケーブルで曲を取り込む"
        case .chinese: return "使用数据线导入曲目"
        case .english: return "Import Songs via Cable"
        }
    }

    static var cableTransferStep1: String {
        switch AppLanguage.current {
        case .japanese: return "1. USB ケーブルで iPhone を Mac または PC に接続します。"
        case .chinese: return "1. 使用 USB 数据线将 iPhone 连接至 Mac 或 PC。"
        case .english: return "1. Connect your iPhone to Mac or PC via USB cable."
        }
    }

    static var cableTransferStep2: String {
        switch AppLanguage.current {
        case .japanese: return "2. Mac の「Finder」または PC の「iTunes」でデバイスを選択します。"
        case .chinese: return "2. 在 Mac 的「访达 (Finder)」或 PC 的「iTunes」中选中您的设备。"
        case .english: return "2. Select your device in Mac Finder or PC iTunes."
        }
    }

    static var cableTransferStep3: String {
        switch AppLanguage.current {
        case .japanese: return "3.「ファイル」タブを開き、「Hana Music」を見つけます。"
        case .chinese: return "3. 点击「文件 (Files)」选项卡，找到「Hana Music」。"
        case .english: return "3. Click 'Files' tab and locate 'Hana Music'."
        }
    }

    static var cableTransferStep4: String {
        switch AppLanguage.current {
        case .japanese: return "4. 音楽ファイルをアプリフォルダにドラッグすると、「ローカル音源スキャン」で一括読み込めます。"
        case .chinese: return "4. 将音频文件拖入应用文件夹中，随后在「本地音频文件扫描」中即可一键载入。"
        case .english: return "4. Drag audio files into app folder, then scan in 'Scan Local Audio'."
        }
    }

    static var airDropTitle: String {
        switch AppLanguage.current {
        case .japanese: return "AirDrop (エアドロップ)"
        case .chinese: return "隔空投送 (AirDrop)"
        case .english: return "AirDrop"
        }
    }

    static var airDropDesc: String {
        switch AppLanguage.current {
        case .japanese: return "Mac や iPad、他の iPhone から AirDrop で音源ファイル（MP3, FLAC, M4A, WAV 等）を送信し、「Hana Music」を選択すると自動で取り込まれ再生できます。"
        case .chinese: return "从 Mac、iPad 或其他 iPhone 上，通过隔空投送发送任意音频文件（MP3, FLAC, M4A, WAV 等），在弹出菜单中选择「Hana Music」，即可自动导入并直接播放。"
        case .english: return "Send any audio file via AirDrop from Mac, iPad, or iPhone. Select 'Hana Music' to import and play automatically."
        }
    }

    static var userGuideTitle: String {
        switch AppLanguage.current {
        case .japanese: return "よくある使い方ガイド"
        case .chinese: return "常见使用指南"
        case .english: return "User Guide"
        }
    }

    static var userGuideItem1: String {
        switch AppLanguage.current {
        case .japanese: return "・ライブラリ：プレイリスト、アーティスト、アルバム、曲、最近追加した項目を一覧集約。"
        case .chinese: return "• 资料库：聚合所有歌单、艺术家、专辑、曲目及最近添加。"
        case .english: return "• Library: Aggregates playlists, artists, albums, songs, and recently added."
        }
    }

    static var userGuideItem2: String {
        switch AppLanguage.current {
        case .japanese: return "・ローカルスキャン：サンドボックスや書類内の外部音楽ファイルを高速検出。"
        case .chinese: return "• 本地扫描：自动检索沙盒和文档中的外部音频文件。"
        case .english: return "• Local Scan: Rapidly discovers external audio files in documents."
        }
    }

    static var userGuideItem3: String {
        switch AppLanguage.current {
        case .japanese: return "・iTunes 同期：Apple Music / iTunes 音楽ライブラリの変更を手動で即時反映。"
        case .chinese: return "• iTunes 手动同步：实时将 Apple Music / iTunes 音乐库变动拉取到应用。"
        case .english: return "• iTunes Sync: Real-time sync of library changes into the app."
        }
    }

    static var userGuideItem4: String {
        switch AppLanguage.current {
        case .japanese: return "・CarPlay 車載：Apple Music に完全準拠した 5 タブ構成とシークバー操作に対応。"
        case .chinese: return "• CarPlay 车载：完美复刻 Apple Music 交互，支持车机进度条拖拽与待播清单。"
        case .english: return "• CarPlay: Full Apple Music experience with 5 tabs, scrub bar and queue."
        }
    }

    static var audioOutput: String {
        switch AppLanguage.current {
        case .japanese: return "オーディオ出力"
        case .chinese: return "音频输出"
        case .english: return "Audio Output"
        }
    }

    static var highQualityLossless: String {
        switch AppLanguage.current {
        case .japanese: return "ハイレゾ・ロスレス高音質出力"
        case .chinese: return "高品质无损音频输出"
        case .english: return "Hi-Res Lossless Audio Output"
        }
    }

    static var smoothCrossfade: String {
        switch AppLanguage.current {
        case .japanese: return "スムーズなクロスフェード (Crossfade)"
        case .chinese: return "平滑淡入淡出 (Crossfade)"
        case .english: return "Smooth Crossfade"
        }
    }

    static var carSettings: String {
        switch AppLanguage.current {
        case .japanese: return "車載設定"
        case .chinese: return "车载设置"
        case .english: return "Car Settings"
        }
    }

    static var carPlayAutoResume: String {
        switch AppLanguage.current {
        case .japanese: return "CarPlay 自動再開"
        case .chinese: return "CarPlay 自动续播"
        case .english: return "CarPlay Auto-Resume"
        }
    }

    static var enabled: String {
        switch AppLanguage.current {
        case .japanese: return "オン"
        case .chinese: return "开启"
        case .english: return "On"
        }
    }

    static var soundGuideTitle: String {
        switch AppLanguage.current {
        case .japanese: return "オーディオ仕様について"
        case .chinese: return "音频特性说明"
        case .english: return "Audio Specifications"
        }
    }

    static var soundGuideDesc1: String {
        switch AppLanguage.current {
        case .japanese: return "Hana Music は最大 192kHz/24-bit のハイレゾ音源に対応。FLAC, ALAC, WAV, AAC, MP3 など多様なフォーマットを高音质で再生します。"
        case .chinese: return "Hana Music 支持最高 192kHz/24-bit 无损音频播放，涵盖 FLAC, ALAC, WAV, AAC, MP3 等主流音频格式。"
        case .english: return "Hana Music supports up to 192kHz/24-bit lossless playback covering FLAC, ALAC, WAV, AAC, MP3 formats."
        }
    }

    static var soundGuideDesc2: String {
        switch AppLanguage.current {
        case .japanese: return "システム標準の AVAudioSession 長時間オーディオ戦略を採用し、ロック画面、コントロールセンター、CarPlay、Bluetooth と完全に連携します。"
        case .chinese: return "支持系统级 AVAudioSession 长音频播放策略，与锁屏控制中心、CarPlay 及蓝牙设备保持无缝握手。"
        case .english: return "Adopts system-level AVAudioSession for seamless integration with Lock Screen, Control Center, CarPlay, and Bluetooth."
        }
    }

    static var carPlayFeatures: String {
        switch AppLanguage.current {
        case .japanese: return "CarPlay 車載機能"
        case .chinese: return "CarPlay 车载功能"
        case .english: return "CarPlay Features"
        }
    }

    static var carPlayFeature1: String {
        switch AppLanguage.current {
        case .japanese: return "・5 タブ構成：今すぐ聴く、ライブラリ、プレイリスト、検索、再生中。"
        case .chinese: return "• 五栏架构：今すぐ聴く、资料库、歌单、搜索、正在播放。"
        case .english: return "• 5-Tab Architecture: Listen Now, Library, Playlists, Search, Now Playing."
        }
    }

    static var carPlayFeature2: String {
        switch AppLanguage.current {
        case .japanese: return "・シークバー操作：車載タッチパネルやダイヤルで曲の進行位置を直接操作可能。"
        case .chinese: return "• 进度条交互拖拽：支持直接在车机触摸屏或旋钮上拖动时间滑块跳转。"
        case .english: return "• Interactive Progress Bar: Drag scrub bar directly on CarPlay screen or knob."
        }
    }

    static var carPlayFeature3: String {
        switch AppLanguage.current {
        case .japanese: return "・お気に入り連動：車載画面のハートボタンとスマホ側がリアルタイム同期。ステアリングスイッチにも対応。"
        case .chinese: return "• 喜欢/收藏联动：车机播放界面红心按键与手机端实时双向同步，并适配方向盘按键。"
        case .english: return "• Favorite Sync: Heart button syncs in real-time with device and steering wheel controls."
        }
    }

    static var carPlayFeature4: String {
        switch AppLanguage.current {
        case .japanese: return "・次に再生・アルバム遷移：再生中画面からキュー確認やアルバムへのジャンプに対応。"
        case .chinese: return "• 待播清单与专辑直达：正在播放页面支持一键呼出队列或下钻专辑。"
        case .english: return "• Playing Next & Album: Jump directly to album or view queue from player."
        }
    }

    // MARK: - 存储管理
    static var storageDetails: String {
        switch AppLanguage.current {
        case .japanese: return "ストレージ詳細"
        case .chinese: return "存储详情"
        case .english: return "Storage Details"
        }
    }

    static var storageFooterTip: String {
        switch AppLanguage.current {
        case .japanese: return "削除可能な項目をタップして空き容量を増やす"
        case .chinese: return "轻点可清理项目以释放存储空间"
        case .english: return "Tap cleanable items to free up space"
        }
    }

    static var usedStorage: String {
        switch AppLanguage.current {
        case .japanese: return "使用済み容量"
        case .chinese: return "已用容量"
        case .english: return "Used Space"
        }
    }

    static var cleanStorageAlertTitle: String {
        switch AppLanguage.current {
        case .japanese: return "キャッシュ削除"
        case .chinese: return "清理缓存"
        case .english: return "Clean Cache"
        }
    }

    static func cleanConfirmMsg(_ name: String) -> String {
        switch AppLanguage.current {
        case .japanese: return "「\(name)」のキャッシュデータを削除してもよろしいですか？"
        case .chinese: return "是否确认清除「\(name)」的缓存数据？"
        case .english: return "Are you sure you want to clean cache for '\(name)'?"
        }
    }

    static var cleanAction: String {
        switch AppLanguage.current {
        case .japanese: return "削除"
        case .chinese: return "清理"
        case .english: return "Clean"
        }
    }

    // 存储细项名称
    static var storageMusic: String {
        switch AppLanguage.current {
        case .japanese: return "音楽ファイル"
        case .chinese: return "音乐文件"
        case .english: return "Music Files"
        }
    }

    static var storageCover: String {
        switch AppLanguage.current {
        case .japanese: return "アルバムアート"
        case .chinese: return "封面数据"
        case .english: return "Artwork Data"
        }
    }

    static var storageImageCache: String {
        switch AppLanguage.current {
        case .japanese: return "画像キャッシュ"
        case .chinese: return "图片缓存"
        case .english: return "Image Cache"
        }
    }

    static var storageNetCache: String {
        switch AppLanguage.current {
        case .japanese: return "ネットワークキャッシュ"
        case .chinese: return "网络缓存"
        case .english: return "Network Cache"
        }
    }

    static var storageOfflineSongs: String {
        switch AppLanguage.current {
        case .japanese: return "オフライン保存曲"
        case .chinese: return "离线缓存曲目"
        case .english: return "Offline Songs"
        }
    }

    static var storageLogs: String {
        switch AppLanguage.current {
        case .japanese: return "ログファイル"
        case .chinese: return "日志文件"
        case .english: return "Log Files"
        }
    }

    static var storageTemp: String {
        switch AppLanguage.current {
        case .japanese: return "一時ファイル"
        case .chinese: return "临时文件"
        case .english: return "Temporary Files"
        }
    }

    static var storageSystem: String {
        switch AppLanguage.current {
        case .japanese: return "システムキャッシュ"
        case .chinese: return "系统缓存"
        case .english: return "System Cache"
        }
    }

    static var storageDatabase: String {
        switch AppLanguage.current {
        case .japanese: return "データベース"
        case .chinese: return "数据库"
        case .english: return "Database"
        }
    }

    static var storageOther: String {
        switch AppLanguage.current {
        case .japanese: return "その他のデータ"
        case .chinese: return "其他数据"
        case .english: return "Other Data"
        }
    }

    static var badgeOptimized: String {
        switch AppLanguage.current {
        case .japanese: return "最適化済"
        case .chinese: return "优化"
        case .english: return "Optimized"
        }
    }

    static var badgeCleanable: String {
        switch AppLanguage.current {
        case .japanese: return "削除可能"
        case .chinese: return "可清理"
        case .english: return "Cleanable"
        }
    }

    // MARK: - 关于界面
    static var appVersionDesc: String {
        switch AppLanguage.current {
        case .japanese: return "バージョン 1.0 (Liquid Glass)"
        case .chinese: return "版本 1.0 (Liquid Glass)"
        case .english: return "Version 1.0 (Liquid Glass)"
        }
    }

    static var devTeam: String {
        switch AppLanguage.current {
        case .japanese: return "開発チーム"
        case .chinese: return "开发团队"
        case .english: return "Development Team"
        }
    }

    static var developer: String {
        switch AppLanguage.current {
        case .japanese: return "開発者"
        case .chinese: return "开发者"
        case .english: return "Developer"
        }
    }

    static var developerName: String {
        switch AppLanguage.current {
        case .japanese: return "千夏 (Chinatsu)"
        case .chinese: return "千夏"
        case .english: return "Chinatsu"
        }
    }

    static var aboutApp: String {
        switch AppLanguage.current {
        case .japanese: return "アプリについて"
        case .chinese: return "关于应用"
        case .english: return "About App"
        }
    }

    static var archMode: String {
        switch AppLanguage.current {
        case .japanese: return "アーキテクチャ"
        case .chinese: return "架构模式"
        case .english: return "Architecture"
        }
    }

    static var uiStyle: String {
        switch AppLanguage.current {
        case .japanese: return "UI スタイル"
        case .chinese: return "界面风格"
        case .english: return "UI Style"
        }
    }

    // MARK: - 播放器及更多菜单
    static var unknownTrack: String {
        switch AppLanguage.current {
        case .japanese: return "名称未設定の曲"
        case .chinese: return "未知曲目"
        case .english: return "Unknown Track"
        }
    }

    static var unknownArtist: String {
        switch AppLanguage.current {
        case .japanese: return "不明なアーティスト"
        case .chinese: return "未知艺术家"
        case .english: return "Unknown Artist"
        }
    }

    static var unknownAlbum: String {
        switch AppLanguage.current {
        case .japanese: return "不明なアルバム"
        case .chinese: return "未知专辑"
        case .english: return "Unknown Album"
        }
    }

    static var songOptions: String {
        switch AppLanguage.current {
        case .japanese: return "曲のオプション"
        case .chinese: return "歌曲选项"
        case .english: return "Song Options"
        }
    }

    static var nextToPlay: String {
        switch AppLanguage.current {
        case .japanese: return "次の曲を再生"
        case .chinese: return "下一首播放"
        case .english: return "Play Next"
        }
    }

    static var toggleShuffle: String {
        switch AppLanguage.current {
        case .japanese: return "シャッフル再生切替"
        case .chinese: return "切换随机播放"
        case .english: return "Toggle Shuffle"
        }
    }

    static var unfavorite: String {
        switch AppLanguage.current {
        case .japanese: return "お気に入りを解除"
        case .chinese: return "取消喜欢"
        case .english: return "Unfavorite"
        }
    }

    // MARK: - 提示与弹窗
    static var fileImport: String {
        switch AppLanguage.current {
        case .japanese: return "ファイル取り込み"
        case .chinese: return "文件导入"
        case .english: return "File Import"
        }
    }

    static func importSuccessMsg(count: Int, names: String) -> String {
        switch AppLanguage.current {
        case .japanese: return "\(count) 個のファイルを取り込みました：\n\(names)"
        case .chinese: return "成功导入 \(count) 个文件：\n\(names)"
        case .english: return "Successfully imported \(count) files:\n\(names)"
        }
    }

    static func importFailMsg(_ error: String) -> String {
        switch AppLanguage.current {
        case .japanese: return "取り込み失敗：\(error)"
        case .chinese: return "导入失败：\(error)"
        case .english: return "Import failed: \(error)"
        }
    }
    static var editSongInfo: String {
        switch AppLanguage.current {
        case .japanese: return "曲の情報を編集"
        case .chinese: return "编辑歌曲信息"
        case .english: return "Edit Song Info"
        }
    }

    static var songInfo: String {
        switch AppLanguage.current {
        case .japanese: return "曲の情報"
        case .chinese: return "歌曲信息"
        case .english: return "Song Info"
        }
    }

    static var noRecentAlbums: String {
        switch AppLanguage.current {
        case .japanese: return "最近追加したアルバムはありません"
        case .chinese: return "暂无最近添加的专辑"
        case .english: return "No Recently Added Albums"
        }
    }

    static var noImportedAudio: String {
        switch AppLanguage.current {
        case .japanese: return "取り込んだ外部音源はありません"
        case .chinese: return "暂无导入的外部音频"
        case .english: return "No Imported Audio"
        }
    }

    static var tapPlusToImport: String {
        switch AppLanguage.current {
        case .japanese: return "右上の「+」をタップして音源を取り込みます"
        case .chinese: return "点击右上角 + 号导入音频文件进行播放"
        case .english: return "Tap + at top right to import audio files"
        }
    }
    static var unknownGenre: String {
        switch AppLanguage.current {
        case .japanese: return "不明なジャンル"
        case .chinese: return "未知流派"
        case .english: return "Unknown Genre"
        }
    }

    static var searchArtists: String {
        switch AppLanguage.current {
        case .japanese: return "アーティストを検索"
        case .chinese: return "搜索艺术家"
        case .english: return "Search Artists"
        }
    }

    static var searchAlbums: String {
        switch AppLanguage.current {
        case .japanese: return "アルバムを検索"
        case .chinese: return "搜索专辑"
        case .english: return "Search Albums"
        }
    }

    static var searchSongs: String {
        switch AppLanguage.current {
        case .japanese: return "曲を検索"
        case .chinese: return "搜索歌曲"
        case .english: return "Search Songs"
        }
    }

    static var searchPlaylists: String {
        switch AppLanguage.current {
        case .japanese: return "プレイリストを検索"
        case .chinese: return "搜索歌单"
        case .english: return "Search Playlists"
        }
    }

    static var searchGenres: String {
        switch AppLanguage.current {
        case .japanese: return "ジャンルを検索"
        case .chinese: return "搜索音乐风格流派"
        case .english: return "Search Genres"
        }
    }

    static var noArtistsFound: String {
        switch AppLanguage.current {
        case .japanese: return "アーティストが見つかりません"
        case .chinese: return "未找到艺术家"
        case .english: return "No Artists Found"
        }
    }

    static var noAlbumsFound: String {
        switch AppLanguage.current {
        case .japanese: return "アルバムが見つかりません"
        case .chinese: return "未找到专辑"
        case .english: return "No Albums Found"
        }
    }

    static var noSongsFound: String {
        switch AppLanguage.current {
        case .japanese: return "曲が見つかりません"
        case .chinese: return "未找到歌曲"
        case .english: return "No Songs Found"
        }
    }

    static var noPlaylistsFound: String {
        switch AppLanguage.current {
        case .japanese: return "プレイリストが見つかりません"
        case .chinese: return "未找到歌单"
        case .english: return "No Playlists Found"
        }
    }

    static var noGenresFound: String {
        switch AppLanguage.current {
        case .japanese: return "ジャンルが見つかりません"
        case .chinese: return "未找到音乐流派"
        case .english: return "No Genres Found"
        }
    }

    static var untitledPlaylist: String {
        switch AppLanguage.current {
        case .japanese: return "名称未設定のプレイリスト"
        case .chinese: return "未命名歌单"
        case .english: return "Untitled Playlist"
        }
    }
}
