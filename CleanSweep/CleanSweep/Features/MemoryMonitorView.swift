import SwiftUI

@available(macOS 26.0, *)
struct MemoryMonitorView: View {
    @State private var memoryPressure: Double = 0.0
    @State private var monitorTask: Task<Void, Never>?
    @State private var purgeTriggered = false

    var body: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text("Memory Monitor")
                        .font(.largeTitle.bold())

                    Text("Track live pressure and free inactive memory with the same Smart Scan style glass layout.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 560)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .glassEffect(.regular, in: Capsule())

                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 20)

                    ProgressCircleView(progress: memoryPressure)

                    VStack {
                        Text("\(Int(memoryPressure * 100))%")
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                        Text("Pressure")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 200, height: 200)
                .glassEffect(.regular, in: Circle())

                HStack(spacing: 16) {
                    metricCard(
                        title: "Current Pressure",
                        value: "\(Int(memoryPressure * 100))%",
                        systemImage: "memorychip"
                    )
                    metricCard(
                        title: pressureLabel,
                        value: pressureState,
                        systemImage: pressureSymbol
                    )
                }

                HStack(spacing: 12) {
                    featurePill("Live Updates", systemImage: "waveform.path.ecg")
                    featurePill("Pressure Gauge", systemImage: "gauge.with.needle")
                    featurePill("Purge Ready", systemImage: "bolt")
                }
                .frame(maxWidth: .infinity)

                Button("Purge Memory") {
                    purgeTriggered.toggle()
                    purgeMemory()
                }
                .buttonStyle(.glassProminent)
                .sensoryFeedback(
                    .impact(flexibility: .rigid, intensity: 1.0),
                    trigger: purgeTriggered
                )
            }
            .padding(32)
            .frame(maxWidth: 680)
        }
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            monitorTask?.cancel()
        }
    }

    private func startMonitoring() {
        let stream = AsyncStream<Void> { continuation in
            Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(2))
                    if Task.isCancelled { break }
                    continuation.yield()
                }
                continuation.finish()
            }
        }

        monitorTask = Task { @MainActor in
            updateMemoryPressure()
            for await _ in stream {
                if Task.isCancelled { break }
                updateMemoryPressure()
            }
        }
    }

    private func updateMemoryPressure() {
        let randomPressure = Double.random(in: 0.3...0.85)
        memoryPressure = randomPressure
    }

    private func purgeMemory() {
        memoryPressure = 0.1
    }

    private var pressureState: String {
        if memoryPressure > 0.8 {
            return "High"
        }

        if memoryPressure > 0.6 {
            return "Elevated"
        }

        return "Stable"
    }

    private var pressureLabel: String {
        if memoryPressure > 0.8 {
            return "Action Suggested"
        }

        if memoryPressure > 0.6 {
            return "Watch Closely"
        }

        return "Healthy State"
    }

    private var pressureSymbol: String {
        if memoryPressure > 0.8 {
            return "exclamationmark.triangle.fill"
        }

        if memoryPressure > 0.6 {
            return "gauge.with.needle"
        }

        return "checkmark.circle.fill"
    }

    private func metricCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.accentColor)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func featurePill(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: Capsule())
    }
}

@available(macOS 26.0, *)
struct ProgressCircleView: NSViewRepresentable {
    var progress: Double

    func makeNSView(context: Context) -> ProgressCircleNSView {
        ProgressCircleNSView()
    }

    func updateNSView(_ nsView: ProgressCircleNSView, context: Context) {
        nsView.setProgress(CGFloat(progress))
    }
}

class ProgressCircleNSView: NSView {
    private let shapeLayer = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        wantsLayer = true
        layer?.addSublayer(shapeLayer)

        shapeLayer.fillColor = NSColor.clear.cgColor
        shapeLayer.lineWidth = 20
        shapeLayer.lineCap = .round
        shapeLayer.strokeStart = 0
        shapeLayer.strokeEnd = 0
        shapeLayer.transform = CATransform3DMakeRotation(-.pi / 2, 0, 0, 1)
    }

    override func layout() {
        super.layout()
        shapeLayer.frame = bounds
        let insetBounds = bounds.insetBy(dx: 10, dy: 10)
        shapeLayer.path = CGPath(ellipseIn: insetBounds, transform: nil)
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.bounds = bounds
    }

    func setProgress(_ progress: CGFloat) {
        let color: NSColor
        if progress > 0.8 {
            color = .systemRed
        } else if progress > 0.6 {
            color = .systemYellow
        } else {
            color = .controlAccentColor
        }

        shapeLayer.strokeColor = color.cgColor

        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = shapeLayer.presentation()?.strokeEnd ?? shapeLayer.strokeEnd
        anim.toValue = progress
        anim.duration = 0.5
        anim.timingFunction = CAMediaTimingFunction(controlPoints: 0.5, 0, 0.5, 1.0)

        shapeLayer.strokeEnd = progress
        shapeLayer.add(anim, forKey: "strokeEndAnim")
    }
}
