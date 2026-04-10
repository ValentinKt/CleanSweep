import SwiftUI
import ScanEngine

@available(macOS 26.0, *)
public struct SmartScanView: View {
    @Bindable var viewModel: SmartScanViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassSpace
    @State private var scanStarted = false
    @State private var cleanTriggered = false

    public init(viewModel: SmartScanViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            switch viewModel.phase {
            case .idle:
                idleView
            case .scanning:
                scanningView
            case .complete:
                summaryView
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.success, trigger: viewModel.phase == .complete)
    }

    private var idleView: some View {
        Button(action: {
            scanStarted.toggle()
            Task { await viewModel.startScan() }
        }) {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                Text("Start Smart Scan")
                    .font(.headline)
            }
            .padding(40)
        }
        .glassEffect(.regular.interactive(), in: Circle())
        .glassEffectID("scanRing", in: glassSpace)
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 1.0), trigger: scanStarted)
    }

    private var scanningView: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: viewModel.progress)

                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.largeTitle.bold().monospacedDigit())
                }
                .frame(width: 200, height: 200)
                .glassEffect(.regular, in: Circle())
                .glassEffectID("scanRing", in: glassSpace)

                VStack(spacing: 8) {
                    Text("Scanning...")
                        .font(.headline)
                    Text(viewModel.activeModuleName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .contentTransition(.numericText())
                    
                    if !viewModel.currentScannedPath.isEmpty {
                        Text(viewModel.currentScannedPath)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.top, 4)
                            .frame(maxWidth: 300)
                    }
                }
            }
        }
    }

    private var summaryView: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 24) {
                Text("Scan Complete")
                    .font(.largeTitle.bold())
                    .glassEffect(.regular, in: Capsule())
                    .glassEffectID("scanRing", in: glassSpace)

                if let summary = viewModel.summary {
                    Text("Found \(formatBytes(summary.totalSize)) to clean")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 16)], spacing: 16) {
                            ForEach(Array(summary.totalSizeByFileCategory.keys), id: \.self) { category in
                                if let size = summary.totalSizeByFileCategory[category], size > 0 {
                                    categoryCard(category: category, size: size)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Button("Clean All") {
                    cleanTriggered.toggle()
                    // TODO: Implement clean
                }
                .glassEffect(.regular.interactive(), in: Capsule())
                .buttonStyle(.plain)
                .padding(.top)
                .sensoryFeedback(.impact(flexibility: .rigid, intensity: 1.0), trigger: cleanTriggered)
            }
        }
        .transition(.blurReplace)
    }

    private func categoryCard(category: FileCategory, size: Int64) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundStyle(Color.accentColor)
                    .font(.title3)
                Text(category.localizedName)
                    .font(.headline)
                Spacer()
                Text(formatBytes(size))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Button("Review & Clean") {
                // Route to detail (to be implemented)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    if #available(macOS 26.0, *) {
        SmartScanView(viewModel: SmartScanViewModel())
    }
}
