import SwiftUI
import ScanEngine

@available(macOS 26.0, *)
struct SmartScanView: View {
    @Bindable var viewModel: SmartScanViewModel
    @Binding var selection: SidebarItem?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassSpace
    @State private var scanStarted = false
    @State private var cleanTriggered = false

    init(viewModel: SmartScanViewModel, selection: Binding<SidebarItem?>) {
        self.viewModel = viewModel
        self._selection = selection
    }

    var body: some View {
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
        GlassEffectContainer(spacing: 18) {
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                VStack(spacing: 10) {
                    Text("Smart Scan")
                        .font(.largeTitle.bold())

                    Text(
                        "Run a balanced cleanup pass with live module routing and Tahoe glass surfaces."
                    )
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)
                }

                Button {
                    scanStarted.toggle()
                    Task { await viewModel.startScan() }
                } label: {
                    Label("Start Smart Scan", systemImage: "magnifyingglass")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }
                .glassEffect(.regular.interactive(), in: Capsule())
                .glassEffectID("scanRing", in: glassSpace)
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(flexibility: .solid, intensity: 1.0), trigger: scanStarted)

                HStack(spacing: 12) {
                    smartScanPill("Balanced Scan", systemImage: "dial.low")
                    smartScanPill("Live Status", systemImage: "waveform.path.ecg")
                    smartScanPill("Module Review", systemImage: "square.grid.2x2")
                }
                .frame(maxWidth: .infinity)
            }
            .padding(32)
            .frame(maxWidth: 640)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private var scanningView: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8),
                            value: viewModel.progress
                        )

                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.largeTitle.bold().monospacedDigit())
                }
                .frame(width: 200, height: 200)
                .glassEffect(.regular, in: Circle())
                .glassEffectID("scanRing", in: glassSpace)

                VStack(spacing: 16) {
                    Text("Scanning")
                        .font(.headline)

                    Text(viewModel.activeModuleName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .truncationMode(.tail)
                        .frame(maxWidth: 320)

                    if !viewModel.currentScannedPath.isEmpty {
                        Text(viewModel.currentScannedPath)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 360)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: 460)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                HStack(spacing: 12) {
                    smartScanPill("Bounded CPU", systemImage: "cpu")
                    smartScanPill("Live Path", systemImage: "folder")
                    smartScanPill("Review Ready", systemImage: "arrow.right.circle")
                }
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
    }

    private var summaryView: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text("Scan Complete")
                        .font(.largeTitle.bold())
                    Text(
                        viewModel.summary.map { "Found \(formatBytes($0.totalSize)) to clean" } ??
                            "Ready for review"
                    )
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .glassEffect(.regular, in: Capsule())
                .glassEffectID("scanRing", in: glassSpace)

                if let summary = viewModel.summary {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 16)], spacing: 16) {
                            ForEach(sortedCategories(for: summary), id: \.category) { item in
                                categoryCard(category: item.category, size: item.size)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Button("Clean All") {
                    cleanTriggered.toggle()
                }
                .buttonStyle(.glassProminent)
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
                if let destination = destination(for: category) {
                    viewModel.prepareReview(for: destination)
                    selection = destination
                }
            }
            .buttonStyle(.glassProminent)
            .controlSize(.small)
        }
        .padding()
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func sortedCategories(for summary: ScanSummary) -> [(category: FileCategory, size: Int64)] {
        summary.totalSizeByFileCategory
            .compactMap { category, size in
                guard size > 0 else { return nil }
                return (category, size)
            }
            .sorted { lhs, rhs in
                if lhs.size == rhs.size {
                    return lhs.category.localizedName < rhs.category.localizedName
                }

                return lhs.size > rhs.size
            }
    }

    private func destination(for category: FileCategory) -> SidebarItem? {
        Self.categoryDestinations[category]
    }

    private func smartScanPill(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: Capsule())
    }

    private static let categoryDestinations: [FileCategory: SidebarItem] = [
        .userCache: .systemJunk,
        .systemLog: .systemJunk,
        .tempFile: .systemJunk,
        .languagePack: .systemJunk,
        .appSupportOrphan: .systemJunk,
        .largeFile: .largeFiles,
        .oldFile: .largeFiles,
        .duplicate: .duplicates,
        .screenshot: .screenshots,
        .screenRecording: .screenshots,
        .xcodeDerivedData: .development,
        .xcodeSimulator: .development,
        .spmCache: .development,
        .trashItem: .trash,
        .mailAttachment: .mailAttachments,
        .browserCache: .networkCache,
        .networkCache: .networkCache,
        .application: .uninstaller,
        .startupItem: .startup,
        .fontDuplicate: .fonts
    ]
}

#Preview {
    if #available(macOS 26.0, *) {
        SmartScanView(viewModel: SmartScanViewModel(), selection: .constant(.smartScan))
    }
}
