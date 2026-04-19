import SwiftUI

@available(macOS 26.0, *)
enum LiquidGlassVariant {
    case clear
    case sidebar
    case accent

    fileprivate var tint: Color {
        switch self {
        case .clear:
            Color.white.opacity(0.08)
        case .sidebar:
            Color(hex: 0x111827, opacity: 0.30)
        case .accent:
            CleanSweepPalette.accentBlue.opacity(0.14)
        }
    }

    fileprivate var material: CleanSweepLiquidGlassMaterial {
        switch self {
        case .clear, .accent:
            .ultraThin
        case .sidebar:
            .thin
        }
    }

    fileprivate var shadowOpacity: Double {
        switch self {
        case .clear:
            0.14
        case .sidebar:
            0.26
        case .accent:
            0.18
        }
    }

    fileprivate var showIridescence: Bool {
        switch self {
        case .clear:
            false
        case .sidebar, .accent:
            true
        }
    }
}

@available(macOS 26.0, *)
private struct LiquidGlassCompatibilityModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let interactive: Bool
    let variant: LiquidGlassVariant

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .cleanSweepLiquidGlass(
                in: shape,
                material: variant.material,
                tint: interactive ? variant.tint.opacity(1.12) : variant.tint,
                shadowOpacity: variant.shadowOpacity,
                showIridescence: variant.showIridescence
            )
            .overlay {
                if interactive && !reduceTransparency {
                    shape
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                }
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
