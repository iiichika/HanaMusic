import SwiftUI

#if os(iOS)
struct StorageItem: Identifiable {
    let id: String
    let icon: String
    let iconColor: Color
    let name: String
    var sizeBytes: Int64
    let isDeletable: Bool
    let badgeText: String?
    let badgeColor: Color?

    var sizeFormatted: String {
        if sizeBytes <= 0 {
            return "0 KB"
        }
        if sizeBytes < 1024 {
            return "\(sizeBytes) B"
        }
        let kb = Double(sizeBytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.0f KB", kb)
        }
        let mb = kb / 1024.0
        if mb < 1024 {
            return String(format: "%.1f MB", mb)
        }
        let gb = mb / 1024.0
        return String(format: "%.2f GB", gb)
    }
}

struct StorageManagementView: View {
    @State private var items: [StorageItem] = [
        StorageItem(id: "music", icon: "music.note.list", iconColor: .blue, name: L10n.storageMusic, sizeBytes: 64, isDeletable: false, badgeText: nil, badgeColor: nil),
        StorageItem(id: "cover", icon: "photo.fill.on.rectangle.fill", iconColor: .orange, name: L10n.storageCover, sizeBytes: 104_400_000, isDeletable: true, badgeText: L10n.badgeOptimized, badgeColor: .blue),
        StorageItem(id: "image_cache", icon: "photo.fill", iconColor: .red, name: L10n.storageImageCache, sizeBytes: 13_200_000, isDeletable: true, badgeText: L10n.badgeCleanable, badgeColor: .green),
        StorageItem(id: "net_cache", icon: "network", iconColor: .green, name: L10n.storageNetCache, sizeBytes: 0, isDeletable: true, badgeText: L10n.badgeCleanable, badgeColor: .green),
        StorageItem(id: "offline_songs", icon: "icloud.and.arrow.down.fill", iconColor: .indigo, name: L10n.storageOfflineSongs, sizeBytes: 0, isDeletable: true, badgeText: L10n.badgeCleanable, badgeColor: .green),
        StorageItem(id: "logs", icon: "doc.text.fill", iconColor: .brown, name: L10n.storageLogs, sizeBytes: 45 * 1024, isDeletable: true, badgeText: L10n.badgeCleanable, badgeColor: .green),
        StorageItem(id: "temp", icon: "clock.arrow.circlepath", iconColor: .orange, name: L10n.storageTemp, sizeBytes: 0, isDeletable: true, badgeText: L10n.badgeCleanable, badgeColor: .green),
        StorageItem(id: "system", icon: "folder.fill", iconColor: .purple, name: L10n.storageSystem, sizeBytes: 952 * 1024, isDeletable: false, badgeText: nil, badgeColor: nil),
        StorageItem(id: "database", icon: "cylinder.split.1x2.fill", iconColor: .cyan, name: L10n.storageDatabase, sizeBytes: 133 * 1024, isDeletable: false, badgeText: nil, badgeColor: nil),
        StorageItem(id: "other", icon: "ellipsis.circle.fill", iconColor: .gray, name: L10n.storageOther, sizeBytes: 21_200_000, isDeletable: false, badgeText: nil, badgeColor: nil)
    ]

    @State private var itemToClean: StorageItem?
    @State private var showCleanAlert: Bool = false

    var totalSizeBytes: Int64 {
        items.reduce(0) { $0 + $1.sizeBytes }
    }

    var totalSizeFormatted: String {
        let mb = Double(totalSizeBytes) / (1024.0 * 1024.0)
        return String(format: "%.0f MB", mb)
    }

    var body: some View {
        List {
            // 顶部已用容量卡片
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.blue)
                            .frame(width: 54, height: 54)
                        Image(systemName: "internaldrive.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.usedStorage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(totalSizeFormatted)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
            }

            // 存储详情分类列表
            Section(
                header: Text(L10n.storageDetails),
                footer: Text(L10n.storageFooterTip)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
            ) {
                ForEach(items) { item in
                    HStack(spacing: 14) {
                        Image(systemName: item.icon)
                            .font(.system(size: 20))
                            .foregroundColor(item.iconColor)
                            .frame(width: 26)

                        Text(item.name)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)

                        if let badge = item.badgeText, let color = item.badgeColor {
                            Text(badge)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(color)
                                .cornerRadius(5)
                        }

                        Spacer()

                        Text(item.sizeFormatted)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        if item.isDeletable {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if item.isDeletable && item.sizeBytes > 0 {
                            itemToClean = item
                            showCleanAlert = true
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.storageManagement)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showCleanAlert) {
            Alert(
                title: Text("\(L10n.cleanStorageAlertTitle) \(itemToClean?.name ?? "")"),
                message: Text(L10n.cleanConfirmMsg(itemToClean?.name ?? "")),
                primaryButton: .destructive(Text(L10n.cleanAction)) {
                    if let target = itemToClean {
                        cleanItem(target)
                    }
                },
                secondaryButton: .cancel(Text(L10n.cancel))
            )
        }
    }

    private func cleanItem(_ target: StorageItem) {
        withAnimation(.spring()) {
            if let index = items.firstIndex(where: { $0.id == target.id }) {
                items[index].sizeBytes = 0
            }
        }
        // 清理实际磁盘沙盒缓存
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                try? fileManager.removeItem(at: cacheURL)
                try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
            }
        }
    }
}
#endif
