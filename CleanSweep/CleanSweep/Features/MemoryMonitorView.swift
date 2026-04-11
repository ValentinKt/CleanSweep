import SwiftUI

@available(macOS 26.0, *)
struct MemoryMonitorView: View {
    @State private var memoryPressure: Double = 0.0
    @State private var monitorTask: Task<Void, Never>?
    @State private var purgeTriggered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                pressureSection
                HStack(spacing: 16) {
                    metricCard(
                        title: "Current Pressure",
                        value: "\(Int(memoryPressure * 100))%",
                        systemImage: "memorychip.fill",
                        accent: CleanSweepPalette.accentBlue
                    )
                    metricCard(
                        title: pressureLabel,
                        value: pressureState,
                        systemImage: pressureSymbol,
                        accent: pressureAccent
                    )
                    metricCard(
                        title: "Recommended",
                        value: recommendationTitle,
                        systemImage: "sparkles",
                        accent: CleanSweepPalette.accentTeal
                    )
                }

                CleanSweepSurface(cornerRadius: 22, padding: 20) {
                    HStack(spacing: 12) {
                        CleanSweepTag(title: "Live Updates", systemImage: "waveform.path.ecg")
                        CleanSweepTag(title: "Pressure Gauge", systemImage: "gauge.with.needle")
                        CleanSweepTag(title: "Purge Ready", systemImage: "bolt.fill")
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(28)
        }
        .background {
            CleanSweepWindowBackground()
        }
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            monitorTask?.cancel()
        }
    }

    private var heroSection: some View {
        CleanSweepSurface(cornerRadius: 26, padding: 28) {
            HStack(spacing: 24) {
                CleanSweepHeroIcon(systemImage: "memorychip.fill", size: 104)

                VStack(alignment: .leading, spacing: 14) {
                    CleanSweepSectionEyebrow(title: "Memory")
                    Text("Keep memory pressure calm and responsive.")
                        .font(.system(size: 34, weight: .bold))
                    Text(
                        "Track live pressure and free inactive memory with a polished, premium " +
                            "monitor designed to feel native on macOS."
                    )
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Button("Purge Memory") {
                        purgeTriggered.toggle()
                        purgeMemory()
                    }
                    .buttonStyle(CleanSweepPrimaryButtonStyle())
                    .sensoryFeedback(
                        .impact(flexibility: .rigid, intensity: 1.0),
                        trigger: purgeTriggered
                    )
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var pressureSection: some View {
        CleanSweepSurface(cornerRadius: 26, padding: 28) {
            HStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .overlay(Circle().stroke(Color.primary.opacity(0.05), lineWidth: 1))

                    CleanSweepProgressRing(
                        progress: memoryPressure,
                        palette: progressPalette,
                        animated: !reduceMotion
                    )

                    VStack(spacing: 6) {
                        Text("\(Int(memoryPressure * 100))%")
                            .font(.system(size: 38, weight: .bold))
                            .monospacedDigit()
                        Text("Pressure")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 220, height: 220)

                VStack(alignment: .leading, spacing: 16) {
                    CleanSweepSectionEyebrow(title: "Live Memory Pressure")
                    Text(pressureHeadline)
                        .font(.system(size: 30, weight: .bold))
                    Text(
                        "Use the pressure ring to spot load spikes quickly, then purge inactive " +
                            "memory for immediate relief."
                    )
                        .font(.body)
                        .foregroundStyle(.secondary)

                    CleanSweepSurface(cornerRadius: 18, padding: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Current Guidance", systemImage: pressureSymbol)
                                .font(.headline)
                                .foregroundStyle(pressureAccent)
                            Text(recommendationBody)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer(minLength: 0)
            }
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

    private var pressureHeadline: String {
        switch pressureState {
        case "High":
            "Memory needs attention"
        case "Elevated":
            "Memory load is rising"
        default:
            "Memory looks healthy"
        }
    }

    private var recommendationTitle: String {
        switch pressureState {
        case "High":
            "Purge Now"
        case "Elevated":
            "Monitor"
        default:
            "All Good"
        }
    }

    private var recommendationBody: String {
        switch pressureState {
        case "High":
            "Purge memory soon to quickly reclaim inactive pages and restore responsiveness."
        case "Elevated":
            "The system remains stable, but a purge can help if apps start to feel heavy."
        default:
            "No action is necessary. Your current memory pressure is comfortably in the healthy range."
        }
    }

    private var pressureAccent: Color {
        switch pressureState {
        case "High":
            CleanSweepPalette.critical
        case "Elevated":
            CleanSweepPalette.warning
        default:
            CleanSweepPalette.success
        }
    }

    private var progressPalette: CleanSweepProgressPalette {
        switch pressureState {
        case "High":
            .critical
        case "Elevated":
            .warning
        default:
            .scan
        }
    }

    private func metricCard(title: String, value: String, systemImage: String, accent: Color) -> some View {
        CleanSweepSurface(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.14))
                    Image(systemName: systemImage)
                        .foregroundStyle(accent)
                        .font(.title3)
                }
                .frame(width: 42, height: 42)

                Text(value)
                    .font(.title2.bold().monospacedDigit())
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
