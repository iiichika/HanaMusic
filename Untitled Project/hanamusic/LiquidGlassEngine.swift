import SwiftUI
import Combine

#if os(iOS)
import UIKit

// MARK: - Liquid Glass 外观控制与折射引擎
final class LiquidGlassConfig: ObservableObject {
    static let shared = LiquidGlassConfig()

    // 外观模式：0 跟随系统，1 浅色模式，2 深色模式
    @Published var appearanceMode: Int {
        didSet {
            UserDefaults.standard.set(appearanceMode, forKey: "hana_appearance_mode")
            applyAppearanceMode()
        }
    }

    // 玻璃折射与毛玻璃强度（0.0 ~ 1.0，支持用户手动自由调节，默认 0.85）
    @Published var glassIntensity: Double {
        didSet {
            UserDefaults.standard.set(glassIntensity, forKey: "hana_glass_intensity")
        }
    }

    init() {
        self.appearanceMode = UserDefaults.standard.integer(forKey: "hana_appearance_mode")
        let savedIntensity = UserDefaults.standard.double(forKey: "hana_glass_intensity")
        // 如果未曾保存过（值为 0），赋予默认推荐值 0.85
        self.glassIntensity = savedIntensity > 0 ? savedIntensity : 0.85
        applyAppearanceMode()
    }

    // 计算当前设备实际生效的玻璃强度与折射因子
    func effectiveIntensity(reduceTransparency: Bool) -> Double {
        if reduceTransparency {
            // 系统辅助功能开启「降低透明度」时，按规范完全降级为无折射实体材质
            return 0.0
        }
        return min(max(glassIntensity, 0.05), 1.0)
    }

    // 恢复默认折射强度
    func resetToDefault() {
        glassIntensity = 0.85
    }

    // 切换外观模式：浅色、深色、跟随系统全部生效，并实时联动整个应用的所有 UIWindow
    func applyAppearanceMode() {
        DispatchQueue.main.async {
            let style: UIUserInterfaceStyle
            switch self.appearanceMode {
            case 1:
                style = .light
            case 2:
                style = .dark
            default:
                style = .unspecified
            }
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        window.overrideUserInterfaceStyle = style
                    }
                }
            }
        }
    }
}

// MARK: - 流体液态玻璃修饰器 (Liquid Glass Modifier)
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var dragOffset: CGSize = .zero
    var isDragging: Bool = false

    @ObservedObject private var config = LiquidGlassConfig.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let intensity = config.effectiveIntensity(reduceTransparency: reduceTransparency)
        let isDarkMode = colorScheme == .dark

        // 流体拉伸与挤压形变计算 (Squash & Stretch Physics)
        let stretchX = isDragging ? 1.0 + min(0.08, dragOffset.width * 0.0006) : 1.0
        let stretchY = isDragging ? 1.0 - min(0.04, abs(dragOffset.height) * 0.0004) : 1.0

        content
            .background(
                glassBackground(intensity: intensity, isDarkMode: isDarkMode)
            )
            .overlay(
                glassSpecularHighlight(intensity: intensity, isDarkMode: isDarkMode)
            )
            .shadow(
                color: Color.black.opacity(isDarkMode ? 0.35 * intensity : 0.12 * intensity),
                radius: isDragging ? 20 : 14,
                x: dragOffset.width * 0.1,
                y: 7 + dragOffset.height * 0.15
            )
            .scaleEffect(x: stretchX, y: stretchY)
            .offset(x: dragOffset.width * 0.45, y: dragOffset.height * 0.35)
    }

    // MARK: - 动态背景分级实现（完全响应用户手动调节的折射强度与系统外观）
    @ViewBuilder
    private func glassBackground(intensity: Double, isDarkMode: Bool) -> some View {
        if reduceTransparency || intensity <= 0.05 {
            // 辅助功能「降低透明度」或强度归零：Apple 官方推荐高对比度实体防眩光材质
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        } else {
            // Liquid Glass 材质：分层超薄材质 + 动态高光渐变
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(max(0.25, intensity))

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity((isDarkMode ? 0.16 : 0.28) * intensity),
                                (isDarkMode ? Color.black : Color.white).opacity(0.05 * intensity),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }

    // MARK: - 高精度玻璃镜面边缘高光 (Specular Highlight Border)
    private func glassSpecularHighlight(intensity: Double, isDarkMode: Bool) -> some View {
        let topAlpha = isDarkMode ? 0.40 * intensity : 0.62 * intensity
        let bottomAlpha = isDarkMode ? 0.10 * intensity : 0.25 * intensity

        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(topAlpha),
                        Color.white.opacity(0.14 * intensity),
                        Color.clear,
                        Color.white.opacity(bottomAlpha)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.0
            )
    }
}

// MARK: - 流体外观模式切换组件（浅色、深色、跟随系统均真实生效）
struct FluidAppearancePicker: View {
    @ObservedObject var config = LiquidGlassConfig.shared
    @Namespace private var modeNamespace

    var body: some View {
        HStack(spacing: 0) {
            modeButton(title: L10n.appearanceSystem, icon: "circle.lefthalf.filled", mode: 0)
            modeButton(title: L10n.appearanceLight, icon: "sun.max.fill", mode: 1)
            modeButton(title: L10n.appearanceDark, icon: "moon.fill", mode: 2)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private func modeButton(title: String, icon: String, mode: Int) -> some View {
        let isSelected = config.appearanceMode == mode
        return Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.36, dampingFraction: 0.68, blendDuration: 0.2)) {
                config.appearanceMode = mode
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                            .matchedGeometryEffect(id: "fluidModeIndicator", in: modeNamespace)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

#else

class LiquidGlassConfig: ObservableObject {
    static let shared = LiquidGlassConfig()
    @Published var appearanceMode: Int = 0
    @Published var glassIntensity: Double = 0.85
    func resetToDefault() {}
}

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var dragOffset: CGSize = .zero
    var isDragging: Bool = false
    func body(content: Content) -> some View { content }
}

struct FluidAppearancePicker: View {
    var body: some View { EmptyView() }
}

#endif
