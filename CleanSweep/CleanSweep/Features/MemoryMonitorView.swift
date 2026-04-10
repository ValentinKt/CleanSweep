import SwiftUI
import Combine

@available(macOS 26.0, *)
struct MemoryMonitorView: View {
    @State private var memoryPressure: Double = 0.0
    @State private var monitorTask: Task<Void, Never>?

    var body: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 20) {
                Text("Memory Monitor")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 20)

                    ProgressCircleView(progress: memoryPressure)

                    VStack {
                        Text("\(Int(memoryPressure * 100))%")
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                        Text("Pressure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 200, height: 200)

                Button("Purge Memory") {
                    purgeMemory()
                }
                .glassEffect(.regular.interactive(), in: Capsule())
                .padding(.top, 20)
            }
            .padding(40)
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
        // Simplified dummy implementation since Mach API is complex to call from Swift directly without bridging headers
        // In a real app we would use host_statistics64
        let randomPressure = Double.random(in: 0.3...0.85)
        memoryPressure = randomPressure
    }

    private func purgeMemory() {
        // Dummy implementation
        memoryPressure = 0.1
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
        anim.timingFunction = CAMediaTimingFunction(controlPoints: 0.5, 0, 0.5, 1.0) // Similar to spring response
        
        shapeLayer.strokeEnd = progress
        shapeLayer.add(anim, forKey: "strokeEndAnim")
    }
}
