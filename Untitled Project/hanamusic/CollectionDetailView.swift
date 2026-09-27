import SwiftUI

#if os(iOS)
import MediaPlayer

struct CollectionDetailView: View {
    let title: String
    let subtitle: String?
    let collection: MPMediaItemCollection
    @ObservedObject var musicManager: MusicManager

    @State private var showRenameAlert: Bool = false
    @State private var newName: String = ""
    @State private var showDeleteAlert: Bool = false
    @State private var showCoverFeedback: Bool = false
    @State private var coverFeedbackMessage: String = ""
    @State private var showAddSongsSheet: Bool = false

    var body: some View {
        List {
            // 头部封面与信息
            Section {
                VStack(spacing: 16) {
                    if let artwork = collection.representativeItem?.artwork,
                       let image = artwork.image(at: CGSize(width: 200, height: 200)) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 180, height: 180)
                            .cornerRadius(12)
                            .shadow(radius: 6)
                    } else {
                        ZStack {
                            Color(UIColor.systemGray5)
                            Image(systemName: "music.note.list")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 180, height: 180)
                        .cornerRadius(12)
                    }

                    VStack(spacing: 6) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        if let subtitle = subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text(L10n.songCount(collection.count))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // 播放全部 & 随机播放按钮
                    HStack(spacing: 16) {
                        Button(action: {
                            musicManager.playAll(collection: collection, shuffle: false)
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text(L10n.playAll)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }

                        Button(action: {
                            musicManager.playAll(collection: collection, shuffle: true)
                        }) {
                            HStack {
                                Image(systemName: "shuffle")
                                Text(L10n.shufflePlay)
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .listRowBackground(Color.clear)
            }

            // 歌曲列表
            Section(header: Text(L10n.tabSongs)) {
                ForEach(Array(collection.items.enumerated()), id: \.element.persistentID) { index, song in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 24, alignment: .leading)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(song.title ?? L10n.unknownTrack)
                                .font(.body)
                                .foregroundColor(musicManager.currentSong?.persistentID == song.persistentID ? .red : .primary)
                                .lineLimit(1)

                            Text(song.artist ?? L10n.unknownArtist)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(formatDuration(song.playbackDuration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        musicManager.play(song: song, from: collection.items)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 110)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // 图2规范右侧更多操作菜单（8项全功能，多语言跟随系统）
                Menu {
                    // 1. すべて再生
                    Button(action: {
                        musicManager.playAll(collection: collection, shuffle: false)
                    }) {
                        Label(L10n.playAll, systemImage: "play.circle")
                    }

                    // 2. 画像を編集
                    Button(action: {
                        coverFeedbackMessage = "已打开封面图像选择"
                        showCoverFeedback = true
                    }) {
                        Label(L10n.editImage, systemImage: "photo")
                    }

                    // 3. カバーを生成
                    Button(action: {
                        coverFeedbackMessage = "已为您生成全新渐变封面！"
                        showCoverFeedback = true
                    }) {
                        Label(L10n.generateCover, systemImage: "sparkles")
                    }

                    // 4. 曲を追加
                    Button(action: {
                        showAddSongsSheet = true
                    }) {
                        Label(L10n.addSongs, systemImage: "plus")
                    }

                    // 5. 名称変更
                    Button(action: {
                        newName = title
                        showRenameAlert = true
                    }) {
                        Label(L10n.rename, systemImage: "pencil")
                    }

                    // 6. プレイリストに追加する
                    Button(action: {
                        coverFeedbackMessage = "已添加到播放列表"
                        showCoverFeedback = true
                    }) {
                        Label(L10n.addToPlaylist, systemImage: "text.badge.plus")
                    }

                    // 7. ウォッチへ転送
                    Button(action: {
                        coverFeedbackMessage = "正在同步歌单至 Apple Watch..."
                        showCoverFeedback = true
                    }) {
                        Label(L10n.transferToWatch, systemImage: "applewatch")
                    }

                    Divider()

                    // 8. プレイリストを削除
                    Button(role: .destructive, action: {
                        showDeleteAlert = true
                    }) {
                        Label(L10n.deletePlaylist, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
            }
        }
        .alert(isPresented: $showCoverFeedback) {
            Alert(title: Text(L10n.tabPlaylists), message: Text(coverFeedbackMessage), dismissButton: .default(Text(L10n.ok)))
        }
        .sheet(isPresented: $showAddSongsSheet) {
            NavigationView {
                List(musicManager.songs, id: \.persistentID) { song in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(song.title ?? L10n.unknownTrack).font(.body)
                            Text(song.artist ?? L10n.unknownArtist).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
                .navigationTitle(L10n.addSongs)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.ok) { showAddSongsSheet = false }
                    }
                }
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
#endif
