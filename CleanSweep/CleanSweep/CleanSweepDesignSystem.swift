import SwiftUI
import AppKit

// MARK: - Reusable Glass Effect Modifier

@available(macOS 26.0, *)
struct GlassEffectModifier<S: Shape>: ViewModifier {
    let shape: S
    var tint: Color = .white.opacity(0.06)
    var interactive: Bool = false
    var reduceTransparency: Bool = false

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
        } else {
            content
                .glassEffect(
                    interactive
                        ? .regular.interactive().tint(tint)
                        : .regular.tint(tint),
                    in: shape
                )
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: opacity
        )
    }
}

enum CleanSweepPalette {
    static let accentBlue   = Color(hex: 0x3A86FF) // #3a86ff
    static let accentPurple = Color(hex: 0x8338EC) // #8338ec
    static let accentPink   = Color(hex: 0xFF006E) // #ff006e
    static let buttonBg     = Color(hex: 0xFFBE0B) // #ffbe0b
    static let iconBg = Color(hex: 0xFF4D3D) // Vibrant Reddish-Orange from design
    static let accent = Color(hex: 0xFF7A6B)
    static let sidebarSelection = Color.white.opacity(0.12)

    // Keep legacy names mapped to new colors to prevent breaking views
    static let accentTeal = accentPurple
    static let accentMint = accentPink

    static let error        = accentPink
    static let warning      = buttonBg
    static let success      = accentBlue
    static let critical     = error

    static func canvasTop(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x0B1320) : Color(hex: 0xF8FBFF)
    }

    static func canvasBottom(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x111827) : Color(hex: 0xEEF3F8)
    }

    static func surfaceStart(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.09) : Color.white.opacity(0.94)
    }

    static func surfaceEnd(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.04) : Color(hex: 0xF4F8FC)
    }

    static func surfaceBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.88)
    }

    static func softBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }

    static func shadow(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.28) : Color(hex: 0xA9B8CC, opacity: 0.18)
    }

    static func secondaryShadow(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.18) : Color(hex: 0xD0DBE8, opacity: 0.22)
    }
}

@available(macOS 26.0, *)
struct CleanSweepWindowBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Base deep background
            Color(colorScheme == .dark ? hex(0x04080F) : hex(0xF2F5F9))

            // Subtle texture/depth
            LinearGradient(
                colors: [
                    Color(colorScheme == .dark ? hex(0x0B1424) : hex(0xFFFFFF)),
                    Color(colorScheme == .dark ? hex(0x04080F) : hex(0xE6EBF2))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.8)

            // Top-left glow (Blue)
            RadialGradient(
                colors: [
                    Color(hex: 0x3A86FF).opacity(colorScheme == .dark ? 0.22 : 0.14),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 800
            )

            // Bottom-right glow (Purple/Magenta)
            RadialGradient(
                colors: [
                    Color(hex: 0x8338EC).opacity(colorScheme == .dark ? 0.16 : 0.08),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 800
            )

            // Middle-right subtle glow (Pink/Red)
            RadialGradient(
                colors: [
                    Color(hex: 0xFF006E).opacity(colorScheme == .dark ? 0.08 : 0.05),
                    .clear
                ],
                center: UnitPoint(x: 0.8, y: 0.4),
                startRadius: 0,
                endRadius: 600
            )
        }
        .ignoresSafeArea()
    }

    private func hex(_ val: UInt32) -> Color {
        Color(hex: val)
    }
}

@available(macOS 26.0, *)
struct CleanSweepSurface<Content: View>: View {
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .padding(padding)
            .glassEffect(
                .regular.tint(
                    colorScheme == .dark
                        ? Color(hex: 0x0B121C, opacity: 0.16)
                        : Color.white.opacity(0.12)
                ),
                in: shape
            )
            .background {
                if reduceTransparency {
                    shape.fill(colorScheme == .dark ? Color(hex: 0x111827) : .white)
                }
            }
            .overlay {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.12 : 0.44),
                                Color.white.opacity(colorScheme == .dark ? 0.02 : 0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: CleanSweepPalette.shadow(for: colorScheme), radius: 30, y: 16)
    }
}

@available(macOS 26.0, *)
struct CleanSweepSidebarPanel<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(
        padding: CGFloat = 14,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 44, style: .continuous)

        return GlassEffectContainer {
            content
                .padding(padding)
                .glassEffect(
                    .regular.tint(
                        colorScheme == .dark
                            ? Color(hex: 0x0B1A2D, opacity: 0.12)
                            : Color.white.opacity(0.18)
                    ),
                    in: shape
                )
                .background {
                    if reduceTransparency {
                        shape.fill(colorScheme == .dark ? Color(hex: 0x111827) : .white)
                    }
                }
                .overlay {
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.18 : 0.62),
                                    Color.white.opacity(colorScheme == .dark ? 0.04 : 0.12),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.12), radius: 40, y: 24)
        }
    }
}

@available(macOS 26.0, *)
struct CleanSweepHeroIcon: View {
    let systemImage: String
    var size: CGFloat = 96

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)

        ZStack {
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            CleanSweepPalette.iconBg,
                            CleanSweepPalette.iconBg.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.36),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottom
                    )
                )

            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: size, height: size)
        .modifier(GlassEffectModifier(
            shape: shape,
            tint: CleanSweepPalette.iconBg.opacity(0.18),
            interactive: true,
            reduceTransparency: reduceTransparency
        ))
        .shadow(color: CleanSweepPalette.iconBg.opacity(0.28), radius: 22, y: 14)
    }
}

@available(macOS 26.0, *)
struct CleanSweepSectionEyebrow: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(CleanSweepPalette.iconBg)
    }
}

@available(macOS 26.0, *)
struct CleanSweepPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(buttonBackground(isPressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .shadow(color: CleanSweepPalette.buttonBg.opacity(0.32), radius: 18, y: 10)
            .animation(
                reduceMotion ? nil : .spring(response: 0.26, dampingFraction: 0.72),
                value: configuration.isPressed
            )
    }

    private func buttonBackground(isPressed: Bool) -> some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        CleanSweepPalette.buttonBg.opacity(isPressed ? 0.9 : 1),
                        CleanSweepPalette.buttonBg.opacity(isPressed ? 0.92 : 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.18 : 0.32),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
    }
}

@available(macOS 26.0, *)
struct CleanSweepSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(buttonBackground(isPressed: configuration.isPressed))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(
                        Color.white.opacity(configuration.isPressed ? 0.12 : 0.22),
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.78),
                value: configuration.isPressed
            )
    }

    private func buttonBackground(isPressed: Bool) -> some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        CleanSweepPalette.surfaceStart(for: colorScheme)
                            .opacity(isPressed ? 0.82 : 1),
                        CleanSweepPalette.surfaceEnd(for: colorScheme)
                            .opacity(isPressed ? 0.86 : 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

@available(macOS 26.0, *)
struct CleanSweepTag: View {
    let title: String
    let systemImage: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let shape = Capsule(style: .continuous)

        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(
                .regular.interactive().tint(
                    colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color.white.opacity(0.24)
                ),
                in: shape
            )
            .background {
                if reduceTransparency {
                    shape.fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
                }
            }
            .overlay {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.12 : 0.44),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
    }
}

@available(macOS 26.0, *)
struct CleanSweepMetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    var accent: Color = CleanSweepPalette.iconBg

    var body: some View {
        CleanSweepSurface(cornerRadius: 16, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.14))
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accent)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct CleanSweepProgressPalette {
    let leading: NSColor
    let trailing: NSColor
    let glow: NSColor

    static let scan = CleanSweepProgressPalette(
        leading: NSColor(calibratedRed: 0.98, green: 0.34, blue: 0.03, alpha: 1), // #FB5607
        trailing: NSColor(calibratedRed: 1.00, green: 0.75, blue: 0.04, alpha: 1), // #FFBE0B
        glow: NSColor(calibratedRed: 0.98, green: 0.34, blue: 0.03, alpha: 1)
    )

    static let warning = CleanSweepProgressPalette(
        leading: NSColor(calibratedRed: 1.00, green: 0.80, blue: 0.38, alpha: 1),
        trailing: NSColor(calibratedRed: 1.00, green: 0.57, blue: 0.05, alpha: 1),
        glow: NSColor(calibratedRed: 1.00, green: 0.67, blue: 0.15, alpha: 1)
    )

    static let critical = CleanSweepProgressPalette(
        leading: NSColor(calibratedRed: 1.00, green: 0.52, blue: 0.54, alpha: 1),
        trailing: NSColor(calibratedRed: 0.96, green: 0.19, blue: 0.43, alpha: 1),
        glow: NSColor(calibratedRed: 0.99, green: 0.32, blue: 0.44, alpha: 1)
    )
}

@available(macOS 26.0, *)
struct CleanSweepProgressRing: NSViewRepresentable {
    var progress: Double
    var palette: CleanSweepProgressPalette = .scan
    var animated = true

    func makeNSView(context: Context) -> CleanSweepProgressRingNSView {
        CleanSweepProgressRingNSView()
    }

    func updateNSView(_ nsView: CleanSweepProgressRingNSView, context: Context) {
        nsView.setProgress(progress, palette: palette, animated: animated)
    }
}

final class CleanSweepProgressRingNSView: NSView {
    private let trackLayer = CAShapeLayer()
    private let progressMaskLayer = CAShapeLayer()
    private let glowLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let glossGradientLayer = CAGradientLayer()
    private let glossMaskLayer = CAShapeLayer()
    private let shineLayer = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        wantsLayer = true
        guard let rootLayer = layer else { return }

        trackLayer.fillColor = NSColor.clear.cgColor
        trackLayer.strokeColor = NSColor.white.withAlphaComponent(0.14).cgColor
        trackLayer.lineWidth = 14

        glowLayer.fillColor = NSColor.clear.cgColor
        glowLayer.lineWidth = 22
        glowLayer.lineCap = .round
        glowLayer.lineJoin = .round
        glowLayer.shadowOpacity = 0.34
        glowLayer.shadowRadius = 24
        glowLayer.shadowOffset = .zero

        progressMaskLayer.fillColor = NSColor.clear.cgColor
        progressMaskLayer.lineWidth = 14
        progressMaskLayer.lineCap = .round
        progressMaskLayer.lineJoin = .round
        progressMaskLayer.strokeEnd = 0

        gradientLayer.type = .conic
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.mask = progressMaskLayer

        glossGradientLayer.type = .axial
        glossGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        glossGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        glossGradientLayer.mask = glossMaskLayer

        glossMaskLayer.fillColor = NSColor.clear.cgColor
        glossMaskLayer.lineWidth = 7
        glossMaskLayer.lineCap = .round
        glossMaskLayer.lineJoin = .round
        glossMaskLayer.strokeStart = 0.02
        glossMaskLayer.strokeEnd = 0.26

        shineLayer.fillColor = NSColor.clear.cgColor
        shineLayer.strokeColor = NSColor.white.withAlphaComponent(0.16).cgColor
        shineLayer.lineWidth = 1.2

        rootLayer.addSublayer(trackLayer)
        rootLayer.addSublayer(glowLayer)
        rootLayer.addSublayer(gradientLayer)
        rootLayer.addSublayer(glossGradientLayer)
        rootLayer.addSublayer(shineLayer)
    }

    override func layout() {
        super.layout()

        let baseBounds = bounds.insetBy(dx: 18, dy: 18)
        let rotation = CATransform3DMakeRotation(-.pi / 2, 0, 0, 1)
        let ringPath = progressRingPath(in: baseBounds)

        trackLayer.frame = bounds
        trackLayer.path = ringPath
        trackLayer.transform = CATransform3DIdentity

        glowLayer.frame = bounds
        glowLayer.path = ringPath
        glowLayer.transform = CATransform3DIdentity

        gradientLayer.frame = bounds
        gradientLayer.transform = rotation

        progressMaskLayer.frame = bounds
        progressMaskLayer.path = ringPath
        progressMaskLayer.transform = CATransform3DIdentity

        glossGradientLayer.frame = bounds
        glossMaskLayer.frame = bounds
        glossMaskLayer.path = progressRingPath(in: baseBounds.insetBy(dx: 2, dy: 2))
        glossMaskLayer.transform = CATransform3DIdentity

        shineLayer.frame = bounds
        shineLayer.path = progressRingPath(in: baseBounds.insetBy(dx: 8, dy: 8))
        shineLayer.transform = CATransform3DIdentity
    }

    func setProgress(_ progress: Double, palette: CleanSweepProgressPalette, animated: Bool) {
        let clampedProgress = max(0, min(progress, 1))

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.colors = [
            palette.leading.withAlphaComponent(0.98).cgColor,
            palette.leading.blended(withFraction: 0.35, of: .white)?.cgColor
                ?? palette.leading.cgColor,
            palette.leading.cgColor,
            palette.trailing.cgColor,
            palette.trailing.blended(withFraction: 0.22, of: .white)?.cgColor
                ?? palette.trailing.cgColor,
            palette.leading.cgColor
        ]
        glossGradientLayer.colors = [
            NSColor.white.withAlphaComponent(0.92).cgColor,
            NSColor.white.withAlphaComponent(0.34).cgColor,
            NSColor.clear.cgColor
        ]
        glowLayer.strokeColor = palette.glow.withAlphaComponent(0.68).cgColor
        glowLayer.opacity = clampedProgress == 0 ? 0 : 1
        glossGradientLayer.opacity = clampedProgress == 0 ? 0 : 1
        CATransaction.commit()

        guard animated else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressMaskLayer.strokeEnd = clampedProgress
            glowLayer.strokeEnd = clampedProgress
            CATransaction.commit()
            return
        }

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressMaskLayer.presentation()?.strokeEnd ?? progressMaskLayer.strokeEnd
        animation.toValue = clampedProgress
        animation.duration = 0.55
        animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1, 0.36, 1)

        progressMaskLayer.strokeEnd = clampedProgress
        progressMaskLayer.add(animation, forKey: "strokeEnd")

        glowLayer.removeAnimation(forKey: "strokeEnd")
        glowLayer.strokeEnd = clampedProgress
        glowLayer.add(animation, forKey: "strokeEnd")
    }

    private func progressRingPath(in rect: CGRect) -> CGPath {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle - (CGFloat.pi * 2)
        let path = CGMutablePath()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        return path
    }
}
