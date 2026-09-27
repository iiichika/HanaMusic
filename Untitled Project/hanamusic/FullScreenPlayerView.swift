import SwiftUI

#if os(iOS)
import MediaPlayer
import AVFoundation

struct FullScreenPlayerView: View {
    @ObservedObject var musicManager: MusicManager
    @Environment(\.presentationMode) var presentationMode
    @State private var sliderValue: Double = 0
    @State private var volume: Double = 0.7
    @State private var showActionMenu: Bool = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            let isLandscape = availableWidth > availableHeight

            ZStack {
                // 1. Apple Music 动态流体光晕背景（真正贯穿全屏与上下安全区，杜绝底部白边）
                ambientBackground
                    .ignoresSafeArea(.all)

                // 2. 主播放界面容器（约束在视口内，支持 iPad 居中优雅呈现）
                VStack(spacing: 0) {
                    // 顶部滑动收起手柄（支持点击或向下拉动收起）
                    Button(action: {
                        dismissWithAnimation()
                    }) {
                        Capsule()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 40, height: 5)
                            .padding(.top, 10)
                            .padding(.bottom, 6)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: isLandscape ? 6 : 14)

                    // 3. 居中大尺寸封面（配合 Apple Music 经典的播放/暂停缩放与阴影动效）
                    let artworkDimension: CGFloat = isLandscape
                        ? min(availableHeight * 0.48, 300)
                        : min(availableWidth - 64, availableHeight * 0.38, 360)

                    artworkView(size: max(artworkDimension, 120))
                        .scaleEffect(musicManager.isPlaying ? 1.0 : 0.86)
                        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: musicManager.isPlaying)

                    Spacer(minLength: isLandscape ? 8 : 18)

                    // 4. 歌曲标题、艺术家、喜欢与更多操作
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(musicManager.currentTitle)
                                .font(.system(size: isLandscape ? 18 : 22, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(musicManager.currentArtist)
                                .font(.system(size: isLandscape ? 14 : 17, weight: .regular))
                                .foregroundColor(.white.opacity(0.72))
                                .lineLimit(1)
                        }

                        Spacer()

                        // 心形喜欢/收藏按钮（带轻快弹性反馈动效）
                        Button(action: {
                            if let song = musicManager.currentSong {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    musicManager.toggleFavorite(song: song)
                                }
                            }
                        }) {
                            let isFav = musicManager.currentSong.map { musicManager.isFavorite(song: $0) } ?? false
                            Image(systemName: isFav ? "heart.fill" : "heart")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(isFav ? .red : .white.opacity(0.85))
                                .scaleEffect(isFav ? 1.08 : 1.0)
                                .padding(8)
                        }

                        // 更多选项按钮
                        Button(action: {
                            showActionMenu = true
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(8)
                        }
                    }
                    .padding(.horizontal, 28)

                    Spacer(minLength: isLandscape ? 8 : 14)

                    // 5. Apple Music 极简流体时间进度条
                    VStack(spacing: 6) {
                        AppleMusicProgressBar(
                            value: $sliderValue,
                            total: max(musicManager.duration, 1),
                            onEditingChanged: { editing in
                                musicManager.isScrubbing = editing
                            },
                            onSeek: { newTime in
                                musicManager.seek(to: newTime)
                            }
                        )

                        HStack {
                            Text(formatDuration(sliderValue))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))

                            Spacer()

                            Text("-" + formatDuration(max(0, musicManager.duration - sliderValue)))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 28)

                    Spacer(minLength: isLandscape ? 8 : 16)

                    // 6. Apple Music 纯白实心主控制键（带平滑阻尼缩放动效）
                    HStack {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                musicManager.playPrevious()
                            }
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: isLandscape ? 28 : 34))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                musicManager.togglePlayPause()
                            }
                        }) {
                            Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: isLandscape ? 44 : 54))
                                .foregroundColor(.white)
                                .scaleEffect(musicManager.isPlaying ? 1.0 : 0.95)
                                .frame(maxWidth: .infinity)
                        }

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                musicManager.playNext()
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: isLandscape ? 28 : 34))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: isLandscape ? 8 : 18)

                    // 7. 音量滑条
                    HStack(spacing: 14) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))

                        AppleMusicVolumeBar(volume: $volume)

                        Image(systemName: "speaker.3.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .padding(.horizontal, 28)

                    Spacer(minLength: isLandscape ? 8 : 14)

                    // 8. 底部三大功能图标（歌词、隔空播放 AirPlay、播放队列/循环模式）
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                        }

                        Button(action: {}) {
                            Image(systemName: "airplayaudio")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                        }

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                musicManager.toggleRepeat()
                            }
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.7))

                                if musicManager.repeatMode != .none {
                                    Image(systemName: musicManager.repeatMode == .one ? "repeat.1" : "repeat")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .offset(x: 10, y: -6)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 36)
                    .padding(.bottom, isLandscape ? 12 : 24)
                }
                .frame(width: availableWidth)
                .frame(maxWidth: 580)
                .offset(y: max(0, dragOffset))
            }
            .frame(width: availableWidth, height: availableHeight)
            // 下拉拖拽手势：下拉平滑收起全屏播放器
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 120 || value.velocity.height > 800 {
                            dismissWithAnimation()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .onAppear {
            sliderValue = musicManager.currentPlaybackTime
        }
        .onChange(of: musicManager.currentPlaybackTime) { _, newTime in
            if !musicManager.isScrubbing {
                sliderValue = newTime
            }
        }
        .actionSheet(isPresented: $showActionMenu) {
            ActionSheet(
                title: Text(musicManager.currentTitle),
                message: Text(musicManager.currentArtist),
                buttons: [
                    .default(Text(L10n.nextToPlay)) {
                        if let song = musicManager.currentSong {
                            musicManager.playNext(song: song)
                        }
                    },
                    .default(Text(L10n.toggleShuffle)) {
                        musicManager.toggleShuffle()
                    },
                    .default(Text(musicManager.currentSong.map { musicManager.isFavorite(song: $0) } ?? false ? L10n.unfavorite : L10n.favorites)) {
                        if let song = musicManager.currentSong {
                            musicManager.toggleFavorite(song: song)
                        }
                    },
                    .cancel(Text(L10n.cancel))
                ]
            )
        }
    }

    private func dismissWithAnimation() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        presentationMode.wrappedValue.dismiss()
    }

    // MARK: - 动态模糊背景（彻底铺满全屏，上下左右全安全区穿透覆盖）
    @ViewBuilder
    private var ambientBackground: some View {
        ZStack {
            if let artwork = musicManager.currentArtworkImage {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 65)
                    .overlay(Color.black.opacity(0.48))
            } else {
                LinearGradient(
                    colors: [Color(red: 0.16, green: 0.16, blue: 0.20), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    // MARK: - 大尺寸圆角封面（带 Apple Music 动效阴影）
    @ViewBuilder
    private func artworkView(size: CGFloat) -> some View {
        if let image = musicManager.currentArtworkImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(
                    color: Color.black.opacity(musicManager.isPlaying ? 0.42 : 0.22),
                    radius: musicManager.isPlaying ? 24 : 12,
                    x: 0,
                    y: musicManager.isPlaying ? 14 : 6
                )
        } else {
            ZStack {
                Color.white.opacity(0.08)
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.35))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Apple Music 极简流体进度条（无大滑块，手指触碰直接拉拽）
struct AppleMusicProgressBar: View {
    @Binding var value: Double
    let total: Double
    let onEditingChanged: (Bool) -> Void
    let onSeek: (Double) -> Void

    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let safeTotal = max(total, 0.001)
            let currentValue = isDragging ? dragValue : value
            let progressRatio = min(max(currentValue / safeTotal, 0), 1)

            ZStack(alignment: .leading) {
                // 背景未播放槽位
                Capsule()
                    .fill(Color.white.opacity(0.18))

                // 已播放高亮胶囊（纯白无圆形大滑块）
                Capsule()
                    .fill(Color.white)
                    .frame(width: max(0, width * CGFloat(progressRatio)))
            }
            .frame(height: isDragging ? 8.5 : 4.5)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isDragging)
            .contentShape(Rectangle())
            // 手指触碰或拖动直接拉进度条，无大滑块
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged(true)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        let locationX = min(max(gesture.location.x, 0), width)
                        let ratio = Double(locationX / width)
                        let newTime = ratio * safeTotal
                        dragValue = newTime
                        value = newTime
                    }
                    .onEnded { gesture in
                        let locationX = min(max(gesture.location.x, 0), width)
                        let ratio = Double(locationX / width)
                        let finalTime = ratio * safeTotal
                        value = finalTime
                        isDragging = false
                        onEditingChanged(false)
                        onSeek(finalTime)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            )
        }
        .frame(height: 18) // 扩展手指触控热区
    }
}

// MARK: - Apple Music 极简音量滑条（无大滑块圆点）
struct AppleMusicVolumeBar: View {
    @Binding var volume: Double
    @State private var isDragging: Bool = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progressRatio = min(max(volume, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.18))

                Capsule()
                    .fill(Color.white.opacity(0.88))
                    .frame(width: max(0, width * CGFloat(progressRatio)))
            }
            .frame(height: isDragging ? 8 : 4.5)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isDragging)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let locationX = min(max(gesture.location.x, 0), width)
                        volume = Double(locationX / width)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 18)
    }
}

#endif
