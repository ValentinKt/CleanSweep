import SwiftUI
import AppKit

@available(macOS 14.0, *)
enum CleanSweepLiquidGlassMaterial {
    case ultraThin
    case thin

    fileprivate var visualEffectMaterial: NSVisualEffectView.Material {
        switch self {
        case .ultraThin:
            .hudWindow
        case .thin:
            .sidebar
        }
    }
}

@available(macOS 14.0, *)
struct CleanSweepLiquidGlassModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    var material: CleanSweepLiquidGlassMaterial = .ultraThin
    var tint: Color = .white.opacity(0.08)
    var shadowOpacity: Double = 0.18
    var showIridescence = true

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background { materialBackground }
            .overlay { specularHighlight }
            .overlay { edgeStroke }
            .overlay { innerGlow }
            .clipShape(shape)
            .compositingGroup()
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? shadowOpacity * 1.35 : shadowOpacity * 0.50),
                radius: 28,
                y: 14
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? shadowOpacity * 0.72 : shadowOpacity * 0.24),
                radius: 10,
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
            ZStack {
                CleanSweepVisualEffectView(
                    material: material.visualEffectMaterial,
                    blendingMode: .withinWindow,
                    state: .active
                )

                glassFill

                if showIridescence {
                    iridescenceOverlay
                }
            }
            .clipShape(shape)
            .overlay {
                shape
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.020 : 0.06))
                    .blendMode(.screen)
            }
            .overlay {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(colorScheme == .dark ? 0.18 : 0.10),
                                .clear,
                                tint.opacity(colorScheme == .dark ? 0.12 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            }
            .saturation(colorScheme == .dark ? 1.12 : 1.04)
        }
    }

    private var glassFill: some View {
        shape
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.22),
                        tint.opacity(colorScheme == .dark ? 0.98 : 0.52),
                        Color.black.opacity(colorScheme == .dark ? 0.10 : 0.04),
                        Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08)
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
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.14),
                                tint.opacity(colorScheme == .dark ? 0.18 : 0.08),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            }
    }

    private var iridescenceOverlay: some View {
        shape
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: CleanSweepPalette.accentBlue.opacity(0.10), location: 0.0),
                        .init(color: CleanSweepPalette.accentPurple.opacity(0.08), location: 0.45),
                        .init(color: CleanSweepPalette.accentPink.opacity(0.04), location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.screen)
            .opacity(colorScheme == .dark ? 1 : 0.6)
    }

    private var specularHighlight: some View {
        shape
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.20 : 0.28),
                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )
            )
            .mask(
                Rectangle()
                    .frame(height: 104)
                    .frame(maxHeight: .infinity, alignment: .top)
            )
            .allowsHitTesting(false)
    }

    private var edgeStroke: some View {
        shape
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.18 : 0.30),
                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.10),
                        Color.white.opacity(0.02)
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
            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12), lineWidth: 0.5)
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
        shadowOpacity: Double = 0.18,
        showIridescence: Bool = true
    ) -> some View {
        modifier(
            CleanSweepLiquidGlassModifier(
                shape: shape,
                material: material,
                tint: tint,
                shadowOpacity: shadowOpacity,
                showIridescence: showIridescence
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
    private let showIridescence: Bool
    private let content: Content

    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 24,
        material: CleanSweepLiquidGlassMaterial = .ultraThin,
        tint: Color = .white.opacity(0.08),
        shadowOpacity: Double = 0.18,
        showIridescence: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.material = material
        self.tint = tint
        self.shadowOpacity = shadowOpacity
        self.showIridescence = showIridescence
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
                shadowOpacity: shadowOpacity,
                showIridescence: showIridescence
            )
    }
}

@available(macOS 26.0, *)
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
            .liquidGlass(Capsule(style: .continuous), interactive: false, variant: .tag)
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
