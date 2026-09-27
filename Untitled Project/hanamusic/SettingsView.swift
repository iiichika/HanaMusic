import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import MediaPlayer

// MARK: - 一级设置主界面（完全对齐参考图2：文件管理、设置、关于单列一行，全面接入 L10n 多语言国际化）
struct SettingsView: View {
    @ObservedObject var musicManager: MusicManager
    @ObservedObject private var liquidConfig = LiquidGlassConfig.shared

    @AppStorage("copyFilesInImport") private var copyFilesInImport: Bool = true
    @AppStorage("showAudioQualityInfo") private var showAudioQualityInfo: Bool = true
    @AppStorage("highQualityAudioOutput") private var highQualityAudioOutput: Bool = true
    @AppStorage("smoothCrossfade") private var smoothCrossfade: Bool = false

    // 辅助弹窗与交互状态
    @State private var showFileImporter: Bool = false
    @State private var showWifiTransferSheet: Bool = false
    @State private var showCableTransferSheet: Bool = false
    @State private var showAirDropSheet: Bool = false
    @State private var showUserGuideSheet: Bool = false
    @State private var showPlaybackSettingsSheet: Bool = false
    @State private var showSoundGuideSheet: Bool = false
    @State private var showCarPlayGuideSheet: Bool = false
    @State private var importedFileAlertMessage: String?
    @State private var showImportSuccessAlert: Bool = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        List {
            // MARK: - 1. Liquid Glass 流体毛玻璃与外观交互
            Section(header: Text(L10n.liquidGlassEffect)) {
                // 外观模式流体选择器（跟随系统 / 浅色 / 深色 均真实生效并联动全局所有界面）
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                        Text(L10n.appearanceMode)
                            .font(.system(size: 16, weight: .medium))
                    }
                    FluidAppearancePicker()
                }
                .padding(.vertical, 4)

                // 玻璃折射与毛玻璃强度调节（滑块自由拖动 + 快捷预设档位）
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        Text(L10n.glassIntensity)
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Text("\(Int(liquidConfig.glassIntensity * 100))%")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    // 强度调节滑块
                    Slider(
                        value: $liquidConfig.glassIntensity,
                        in: 0.10...1.0,
                        step: 0.01
                    )
                    .tint(.blue)

                    // 快捷预设档位与重置
                    HStack(spacing: 8) {
                        presetButton(title: L10n.glassPresetSubtle, value: 0.40)
                        presetButton(title: L10n.glassPresetStandard, value: 0.75)
                        presetButton(title: L10n.glassPresetVivid, value: 0.95)
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                liquidConfig.resetToDefault()
                            }
                        }) {
                            Text(L10n.glassResetDefault)
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                    }

                    if reduceTransparency {
                        Text(L10n.reduceTransparencyNote)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 4)

                // 实时材质效果预览卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.glassLivePreview)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ZStack {
                        // 动态渐变背景底色，生动展现流体玻璃折射与通透光泽
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.85),
                                Color.pink.opacity(0.75),
                                Color.orange.opacity(0.75),
                                Color.blue.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        // 浮动 Liquid Glass 卡片（实时应用当前的 modifier）
                        HStack(spacing: 12) {
                            Image(systemName: "waveform")
                                .font(.system(size: 20))
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Liquid Glass Material")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Refraction & Specular Highlight")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.82))
                            }

                            Spacer()

                            Text("\(Int(liquidConfig.glassIntensity * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.24)))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .modifier(LiquidGlassModifier(cornerRadius: 14))
                        .padding(.horizontal, 10)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - 2. 文件管理（包含本地音频扫描、iTunes 音乐库同步、存储管理等）
            Section(header: Text(L10n.fileManagement)) {
                // Wi-Fi 传输
                Button(action: { showWifiTransferSheet = true }) {
                    settingRow(
                        icon: "wifi",
                        iconColor: .blue,
                        title: L10n.wifiTransfer,
                        trailingType: .chevron
                    )
                }
                .buttonStyle(.plain)

                // 数据线传输
                Button(action: { showCableTransferSheet = true }) {
                    settingRow(
                        icon: "cable.connector",
                        iconColor: .green,
                        title: L10n.cableTransfer,
                        trailingType: .chevron
                    )
                }
                .buttonStyle(.plain)

                // 打开文件...（调用系统文件选择器导入外部音频）
                Button(action: { showFileImporter = true }) {
                    settingRow(
                        icon: "folder.fill",
                        iconColor: Color(UIColor.systemYellow),
                        title: L10n.openFile,
                        trailingType: .chevron
                    )
                }
                .buttonStyle(.plain)

                // 隔空投送
                Button(action: { showAirDropSheet = true }) {
                    settingRow(
                        icon: "antenna.radiowaves.left.and.right",
                        iconColor: .cyan,
                        title: L10n.airDrop,
                        trailingType: .chevron
                    )
                }
                .buttonStyle(.plain)

                // 本地音频文件扫描
                Button(action: {
                    musicManager.scanLocalAudioFiles()
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: "waveform.badge.magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                            .frame(width: 26)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.localScan)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            if !musicManager.scannedLocalFiles.isEmpty {
                                Text(L10n.discoveredLocalFiles(musicManager.scannedLocalFiles.count))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if musicManager.isScanningLocalAudio {
                            ProgressView()
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)

                // iTunes 音乐库同步
                Button(action: {
                    musicManager.syncWithITunesLibrary()
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                            .frame(width: 26)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.syncITunes)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            Text(L10n.songsAndAlbumsCount(songs: musicManager.songs.count, albums: musicManager.albums.count))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if musicManager.isSyncingITunes {
                            ProgressView()
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)

                // 存储管理
                NavigationLink(destination: StorageManagementView()) {
                    settingRow(
                        icon: "internaldrive.fill",
                        iconColor: .blue,
                        title: L10n.storageManagement,
                        detailText: L10n.usedStorageText("138 MB"),
                        trailingType: .none
                    )
                }

                // 用户指南
                Button(action: { showUserGuideSheet = true }) {
                    settingRow(
                        icon: "book.closed.fill",
                        iconColor: .indigo,
                        title: L10n.userGuide,
                        trailingType: .chevron
                    )
                }
                .buttonStyle(.plain)
            }

            // MARK: - 3. 系统与播放设置（对齐参考图2设置栏）
            Section(header: Text(L10n.tabSettings)) {
                // 播放设置
                Button(action: { showPlaybackSettingsSheet = true }) {
                    settingRow(
                        icon: "play.circle.fill",
                        iconColor: .blue,
                        title: L10n.playbackSettings,
                        detailText: highQualityAudioOutput ? L10n.highQualityOutputActive : nil,
                        trailingType: .chevron
                    )
                }
                .buttonStyle(.plain)

                // 声音设置指南
                Button(action: { showSoundGuideSheet = true }) {
                    settingRow(
                        icon: "speaker.wave.3.fill",
                        iconColor: .purple,
                        title: L10n.soundSettingsGuide,
                        trailingType: .chevron
                    )
                }
                .buttonStyle(.plain)

                // 车载 CarPlay 架构优化与指南
                Button(action: { showCarPlayGuideSheet = true }) {
                    settingRow(
                        icon: "car.fill",
                        iconColor: .green,
                        title: L10n.carPlay,
                        detailText: L10n.carPlayReady,
                        trailingType: .chevron
                    )
                }
                .buttonStyle(.plain)

                // 导入时拷贝文件（对齐参考图2：インポート時にファイルをコピー）
                Toggle(isOn: $copyFilesInImport) {
                    HStack(spacing: 14) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                            .frame(width: 26)
                        Text(L10n.copyFilesInImport)
                            .font(.system(size: 16))
                    }
                }
                .padding(.vertical, 2)

                // 显示音质信息（对齐参考图2：音質情報を表示）
                Toggle(isOn: $showAudioQualityInfo) {
                    HStack(spacing: 14) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                            .frame(width: 26)
                        Text(L10n.showAudioQualityInfo)
                            .font(.system(size: 16))
                    }
                }
                .padding(.vertical, 2)
            }

            // MARK: - 4. 关于（单列一行）
            Section(header: Text(L10n.about)) {
                NavigationLink(destination: AboutHanaMusicView()) {
                    HStack(spacing: 14) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 26)

                        Text(L10n.aboutHanaMusic)
                            .font(.system(size: 16))

                        Spacer()

                        Text("v1.0.0")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                let fileNames = urls.map { $0.lastPathComponent }.joined(separator: "、")
                importedFileAlertMessage = L10n.importSuccessMsg(count: urls.count, names: fileNames)
                showImportSuccessAlert = true
            case .failure(let error):
                importedFileAlertMessage = L10n.importFailMsg(error.localizedDescription)
                showImportSuccessAlert = true
            }
        }
        .alert(isPresented: $showImportSuccessAlert) {
            Alert(
                title: Text(L10n.fileImport),
                message: Text(importedFileAlertMessage ?? ""),
                dismissButton: .default(Text(L10n.ok))
            )
        }
        .alert(isPresented: $musicManager.showScanResultAlert) {
            Alert(
                title: Text(L10n.localScan),
                message: Text(musicManager.scanResultMessage ?? ""),
                dismissButton: .default(Text(L10n.ok))
            )
        }
        .alert(isPresented: $musicManager.showITunesSyncAlert) {
            Alert(
                title: Text(L10n.syncITunes),
                message: Text(musicManager.iTunesSyncResultMessage ?? ""),
                dismissButton: .default(Text(L10n.ok))
            )
        }
        .sheet(isPresented: $showWifiTransferSheet) {
            wifiTransferSheetView
        }
        .sheet(isPresented: $showCableTransferSheet) {
            cableTransferSheetView
        }
        .sheet(isPresented: $showAirDropSheet) {
            airDropSheetView
        }
        .sheet(isPresented: $showUserGuideSheet) {
            userGuideSheetView
        }
        .sheet(isPresented: $showPlaybackSettingsSheet) {
            playbackSettingsSheetView
        }
        .sheet(isPresented: $showSoundGuideSheet) {
            soundGuideSheetView
        }
        .sheet(isPresented: $showCarPlayGuideSheet) {
            carPlayGuideSheetView
        }
    }

    // MARK: - 辅助列表行构造组件
    enum TrailingType {
        case none
        case chevron
    }

    @ViewBuilder
    private func settingRow(
        icon: String,
        iconColor: Color,
        title: String,
        detailText: String? = nil,
        trailingType: TrailingType = .none
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 26)

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()

            if let detail = detailText {
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            if trailingType == .chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
        .padding(.vertical, 3)
    }

    private func presetButton(title: String, value: Double) -> some View {
        let isSelected = abs(liquidConfig.glassIntensity - value) < 0.03
        return Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                liquidConfig.glassIntensity = value
            }
        }) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue.opacity(0.18) : Color(UIColor.tertiarySystemFill))
                )
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 辅助弹窗视图
    private var wifiTransferSheetView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "wifi")
                    .font(.system(size: 56))
                    .foregroundColor(.blue)
                    .padding(.top, 30)

                Text(L10n.wifiTransferTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(L10n.wifiTransferDesc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("http://192.168.1.108:8080")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)

                Spacer()
            }
            .navigationTitle(L10n.wifiTransfer)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.ok) { showWifiTransferSheet = false }
                }
            }
        }
    }

    private var cableTransferSheetView: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Spacer()
                    Image(systemName: "cable.connector")
                        .font(.system(size: 56))
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.top, 24)

                Text(L10n.cableTransferTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.cableTransferStep1)
                    Text(L10n.cableTransferStep2)
                    Text(L10n.cableTransferStep3)
                    Text(L10n.cableTransferStep4)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(L10n.cableTransfer)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.ok) { showCableTransferSheet = false }
                }
            }
        }
    }

    private var airDropSheetView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 56))
                    .foregroundColor(.cyan)
                    .padding(.top, 30)

                Text(L10n.airDropTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(L10n.airDropDesc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
            .navigationTitle(L10n.airDropTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.ok) { showAirDropSheet = false }
                }
            }
        }
    }

    private var userGuideSheetView: some View {
        NavigationView {
            List {
                Section(header: Text(L10n.userGuideTitle)) {
                    Text(L10n.userGuideItem1)
                    Text(L10n.userGuideItem2)
                    Text(L10n.userGuideItem3)
                    Text(L10n.userGuideItem4)
                }
                .font(.subheadline)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.userGuide)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.ok) { showUserGuideSheet = false }
                }
            }
        }
    }

    private var playbackSettingsSheetView: some View {
        NavigationView {
            List {
                Section(header: Text(L10n.audioOutput)) {
                    Toggle(L10n.highQualityLossless, isOn: $highQualityAudioOutput)
                    Toggle(L10n.smoothCrossfade, isOn: $smoothCrossfade)
                }

                Section(header: Text(L10n.carSettings)) {
                    HStack {
                        Text(L10n.carPlayAutoResume)
                        Spacer()
                        Text(L10n.enabled).foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.playbackSettings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.ok) { showPlaybackSettingsSheet = false }
                }
            }
        }
    }

    private var soundGuideSheetView: some View {
        NavigationView {
            List {
                Section(header: Text(L10n.soundGuideTitle)) {
                    Text(L10n.soundGuideDesc1)
                    Text(L10n.soundGuideDesc2)
                }
                .font(.subheadline)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.soundSettingsGuide)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.ok) { showSoundGuideSheet = false }
                }
            }
        }
    }

    private var carPlayGuideSheetView: some View {
        NavigationView {
            List {
                Section(header: Text(L10n.carPlayFeatures)) {
                    Text(L10n.carPlayFeature1)
                    Text(L10n.carPlayFeature2)
                    Text(L10n.carPlayFeature3)
                    Text(L10n.carPlayFeature4)
                }
                .font(.subheadline)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.carPlay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.ok) { showCarPlayGuideSheet = false }
                }
            }
        }
    }
}
#endif
