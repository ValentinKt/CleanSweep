import SwiftUI
import Combine

@available(macOS 26.0, *)
struct MemoryMonitorView: View {
    @State private var memoryPressure: Double = 0.0
    @State private var timer: AnyCancellable?

    var body: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 20) {
                Text("Memory Monitor")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 20)

                    Circle()
                        .trim(from: 0.0, to: CGFloat(memoryPressure))
                        .stroke(memoryPressure > 0.8 ? Color.red : (memoryPressure > 0.6 ? Color.yellow : Color.accentColor), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: memoryPressure)

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
            timer?.cancel()
        }
    }

    private func startMonitoring() {
        timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect().sink { _ in
            updateMemoryPressure()
        }
        updateMemoryPressure()
    }

    private func updateMemoryPressure() {
        // Simplified dummy implementation since Mach API is complex to call from Swift directly without bridging headers
        // In a real app we would use host_statistics64
        let randomPressure = Double.random(in: 0.3...0.85)
        memoryPressure = randomPressure
    }

    private func purgeMemory() {
        // Dummy implementation
        withAnimation {
            memoryPressure = 0.1
        }
    }
}
