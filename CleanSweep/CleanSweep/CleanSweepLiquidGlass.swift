import SwiftUI

@available(macOS 14.0, *)
enum CleanSweepLiquidGlassMaterial {
    case ultraThin
    case thin
}

@available(macOS 14.0, *)
struct CleanSweepLiquidGlassModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    var material: CleanSweepLiquidGlassMaterial = .ultraThin
    var tint: Color = .white.opacity(0.08)
    var shadowOpacity: Double = 0.18

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let isDarkMode = colorScheme == .dark

        content
            .background { materialBackground }
            .visualEffect { view, proxy in
                view
                    .brightness(proxy.size.height > 160 ? 0.025 : 0.012)
                    .saturation(isDarkMode ? 1.04 : 1.02)
            }
            .overlay { specularHighlight }
            .overlay { edgeStroke }
            .overlay { innerGlow }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? shadowOpacity : shadowOpacity * 0.45),
                radius: 24,
                y: 14
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? shadowOpacity * 0.55 : shadowOpacity * 0.2),
                radius: 8,
                y: 2
            )
    }

    @ViewBuilder
    private var materialBackground: some View {
        if reduceTransparency {
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: .windowBackgroundColor),
                            Color(nsColor: .underPageBackgroundColor)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else {
            switch material {
            case .ultraThin:
                glassFill.background(.ultraThinMaterial, in: shape)
            case .thin:
                glassFill.background(.thinMaterial, in: shape)
            }
        }
    }

    private var glassFill: some View {
        shape
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.48),
                        tint.opacity(colorScheme == .dark ? 0.7 : 0.4),
                        Color.secondary.opacity(colorScheme == .dark ? 0.05 : 0.03),
                        Color.white.opacity(colorScheme == .dark ? 0.03 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(colorScheme == .dark ? 0.22 : 0.12),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            }
    }

    private var specularHighlight: some View {
        shape
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.18 : 0.30),
                        Color.white.opacity(0.10),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )
            )
            .mask(
                Rectangle()
                    .frame(height: 92)
                    .frame(maxHeight: .infinity, alignment: .top)
            )
            .allowsHitTesting(false)
    }

    private var edgeStroke: some View {
        shape
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color.white.opacity(colorScheme == .dark ? 0.06 : 0.03),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .allowsHitTesting(false)
    }

    private var innerGlow: some View {
        shape
            .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            .padding(1)
            .allowsHitTesting(false)
    }
}

@available(macOS 14.0, *)
extension View {
    func cleanSweepLiquidGlass<S: InsettableShape>(
        in shape: S,
        material: CleanSweepLiquidGlassMaterial = .ultraThin,
        tint: Color = .white.opacity(0.08),
        shadowOpacity: Double = 0.18
    ) -> some View {
        modifier(
            CleanSweepLiquidGlassModifier(
                shape: shape,
                material: material,
                tint: tint,
                shadowOpacity: shadowOpacity
            )
        )
    }
}

@available(macOS 14.0, *)
struct CleanSweepLiquidGlassPanel<Content: View>: View {
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let material: CleanSweepLiquidGlassMaterial
    private let tint: Color
    private let shadowOpacity: Double
    private let content: Content

    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 24,
        material: CleanSweepLiquidGlassMaterial = .ultraThin,
        tint: Color = .white.opacity(0.08),
        shadowOpacity: Double = 0.18,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.material = material
        self.tint = tint
        self.shadowOpacity = shadowOpacity
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .padding(padding)
            .cleanSweepLiquidGlass(
                in: shape,
                material: material,
                tint: tint,
                shadowOpacity: shadowOpacity
            )
    }
}

@available(macOS 14.0, *)
struct CleanSweepLiquidDetailHeader: View {
    let selection: SidebarItem?

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            CleanSweepPalette.accentBlue.opacity(0.95),
                            CleanSweepPalette.accentPurple.opacity(0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Image(systemName: selection?.iconName ?? "sidebar.left")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(selection?.localizedName ?? "CleanSweep")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(selectionSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Circle()
                    .fill(CleanSweepPalette.success)
                    .frame(width: 8, height: 8)

                Text("Liquid Glass")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .cleanSweepLiquidGlass(
                in: Capsule(style: .continuous),
                material: .ultraThin,
                tint: CleanSweepPalette.success.opacity(0.10),
                shadowOpacity: 0.06
            )
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
    }

    private var selectionSubtitle: String {
        guard let selection else {
            return "Choose a module to see its vibrant translucent workspace."
        }

        switch selection {
        case .dashboard:
            return "Overview, health metrics, and launch actions."
        case .smartScan:
            return "Run the primary cleanup workflow with animated progress."
        default:
            return "Focused cleanup tools inside a translucent detail surface."
        }
    }
}
