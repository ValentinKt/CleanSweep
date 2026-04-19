import SwiftUI

@available(macOS 26.0, *)
enum LiquidGlassVariant {
    case clear
    case sidebar
    case panel
    case card
    case tag
    case selection
    case accent

    fileprivate var material: CleanSweepLiquidGlassMaterial {
        switch self {
        case .clear, .panel, .card, .tag, .selection, .accent:
            .ultraThin
        case .sidebar:
            .thin
        }
    }

    fileprivate var shadowOpacity: Double {
        switch self {
        case .clear:
            0.10
        case .sidebar:
            0.28
        case .panel:
            0.24
        case .card:
            0.16
        case .tag:
            0.10
        case .selection:
            0.12
        case .accent:
            0.16
        }
    }

    fileprivate var showIridescence: Bool {
        switch self {
        case .clear, .card, .tag, .selection:
            false
        case .sidebar, .panel, .accent:
            true
        }
    }

    fileprivate func tint(for colorScheme: ColorScheme, interactive: Bool) -> Color {
        switch self {
        case .clear:
            return colorScheme == .dark
                ? Color.white.opacity(interactive ? 0.06 : 0.03)
                : Color.white.opacity(interactive ? 0.22 : 0.12)
        case .sidebar:
            return colorScheme == .dark
                ? Color(hex: 0x101827, opacity: interactive ? 0.54 : 0.46)
                : Color.white.opacity(interactive ? 0.26 : 0.18)
        case .panel:
            return colorScheme == .dark
                ? Color(hex: 0x1A2338, opacity: interactive ? 0.36 : 0.30)
                : Color.white.opacity(interactive ? 0.24 : 0.18)
        case .card:
            return colorScheme == .dark
                ? Color(hex: 0x152033, opacity: interactive ? 0.26 : 0.20)
                : Color.white.opacity(interactive ? 0.20 : 0.14)
        case .tag:
            return colorScheme == .dark
                ? Color(hex: 0x111B2E, opacity: interactive ? 0.24 : 0.18)
                : Color.white.opacity(interactive ? 0.24 : 0.16)
        case .selection:
            return colorScheme == .dark
                ? Color.white.opacity(interactive ? 0.16 : 0.11)
                : Color.white.opacity(interactive ? 0.34 : 0.24)
        case .accent:
            return interactive
                ? CleanSweepPalette.iconBg.opacity(0.22)
                : CleanSweepPalette.iconBg.opacity(0.16)
        }
    }

    fileprivate func borderColor(for colorScheme: ColorScheme, interactive: Bool) -> Color {
        switch self {
        case .selection:
            return CleanSweepPalette.iconBg.opacity(interactive ? 0.46 : 0.34)
        case .accent:
            return CleanSweepPalette.iconBg.opacity(interactive ? 0.38 : 0.26)
        case .sidebar:
            return Color.white.opacity(colorScheme == .dark ? (interactive ? 0.22 : 0.14) : 0.24)
        case .panel, .card, .tag, .clear:
            return Color.white.opacity(colorScheme == .dark ? (interactive ? 0.18 : 0.10) : 0.22)
        }
    }

    fileprivate var borderLineWidth: CGFloat {
        switch self {
        case .selection:
            0.95
        case .tag:
            0.75
        default:
            0.85
        }
    }
}

@available(macOS 26.0, *)
private struct LiquidGlassCompatibilityModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let interactive: Bool
    let variant: LiquidGlassVariant

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let tintColor = variant.tint(for: colorScheme, interactive: interactive)
        
        content
            .background {
                if reduceTransparency {
                    shape.fill(.regularMaterial)
                }
            }
            .applyGlassEffect(
                variant: variant,
                interactive: interactive,
                tintColor: tintColor,
                shape: shape,
                isEnabled: !reduceTransparency
            )
            .overlay {
                if !reduceTransparency && (interactive || variant == .selection) {
                    shape
                        .strokeBorder(
                            variant.borderColor(for: colorScheme, interactive: interactive),
                            lineWidth: variant.borderLineWidth
                        )
                }
            }
    }
}

@available(macOS 26.0, *)
private extension View {
    @ViewBuilder
    func applyGlassEffect<S: InsettableShape>(
        variant: LiquidGlassVariant,
        interactive: Bool,
        tintColor: Color,
        shape: S,
        isEnabled: Bool
    ) -> some View {
        if isEnabled {
            if variant == .clear {
                if interactive {
                    self.glassEffect(.clear.interactive().tint(tintColor), in: shape)
                } else {
                    self.glassEffect(.clear.tint(tintColor), in: shape)
                }
            } else {
                if interactive {
                    self.glassEffect(.regular.interactive().tint(tintColor), in: shape)
                } else {
                    self.glassEffect(.regular.tint(tintColor), in: shape)
                }
            }
        } else {
            self
        }
    }
}

@available(macOS 26.0, *)
extension View {
    func liquidGlass<S: InsettableShape>(
        _ shape: S,
        interactive: Bool = false,
        variant: LiquidGlassVariant = .clear
    ) -> some View {
        modifier(
            LiquidGlassCompatibilityModifier(
                shape: shape,
                interactive: interactive,
                variant: variant
            )
        )
    }
}
