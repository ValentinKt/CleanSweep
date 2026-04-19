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
}

@available(macOS 26.0, *)
private struct LiquidGlassCompatibilityModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let interactive: Bool
    let variant: LiquidGlassVariant

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content.cleanSweepGlass(
            in: shape,
            tint: variant.tint,
            interactive: interactive,
            reduceTransparency: reduceTransparency
        )
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
