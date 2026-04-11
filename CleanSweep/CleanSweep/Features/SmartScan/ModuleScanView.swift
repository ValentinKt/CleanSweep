import SwiftUI
import ScanEngine

struct ModuleScanHighlight: Hashable {
    let title: String
    let systemImage: String
}

@available(macOS 26.0, *)
struct ModuleScanView: View {
    @Bindable var viewModel: ModuleScanViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let title: String
    private let systemImage: String
    private let descriptionText: String
    private let highlights: [ModuleScanHighlight]
    private let initialResults: [ScanResult]
    private let initialResultsSeedID: UUID?
    @State private var scanTriggered = false
    @State private var cleanTriggered = false

    init(
        viewModel: ModuleScanViewModel,
        title: String,
        systemImage: String,
        descriptionText: String,
        highlights: [ModuleScanHighlight],
        initialResults: [ScanResult] = [],
        initialResultsSeedID: UUID? = nil
    ) {
        self.viewModel = viewModel
        self.title = title
        self.systemImage = systemImage
        self.descriptionText = descriptionText
        self.highlights = highlights
        self.initialResults = initialResults
        self.initialResultsSeedID = initialResultsSeedID
    }

    var body: some View {
        ScrollView {
            switch viewModel.phase {
            case .idle:
                idleView
            case .scanning:
                scanningView
            case .complete:
                resultsView
            }
        }
        .background {
            CleanSweepWindowBackground()
        }
        .navigationTitle(title)
        .sensoryFeedback(.success, trigger: viewModel.phase == .complete)
        .task(id: initialResultsSeedID) {
            guard initialResultsSeedID != nil, !initialResults.isEmpty else { return }
            viewModel.applySeedResults(initialResults)
        }
    }

    private var idleView: some View {
        VStack(spacing: 24) {
            moduleHero(
                eyebrow: "Focused Cleanup",
                title: title,
                description: descriptionText
            )

            if !highlights.isEmpty {
                CleanSweepSurface(cornerRadius: 22, padding: 20) {
                    HStack(spacing: 12) {
                        ForEach(highlights, id: \.self) { highlight in
                            ModuleFeaturePill(title: highlight.title, systemImage: highlight.systemImage)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(28)
    }

    private var scanningView: some View {
        VStack(spacing: 24) {
            CleanSweepSurface(cornerRadius: 26, padding: 28) {
                HStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.55))
                            .overlay(Circle().stroke(Color.primary.opacity(0.05), lineWidth: 1))

                        CleanSweepProgressRing(
                            progress: max(viewModel.progress, 0.05),
                            animated: !reduceMotion
                        )

                        VStack(spacing: 6) {
                            Text(viewModel.progress > 0 ? "\(Int(viewModel.progress * 100))%" : "…")
                                .font(.system(size: 36, weight: .bold))
                                .monospacedDigit()
                            Text("Scanning")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 220, height: 220)

                    VStack(alignment: .leading, spacing: 14) {
                        CleanSweepSectionEyebrow(title: "Live Module Scan")
                        Text("Review is in progress")
                            .font(.system(size: 30, weight: .bold))
                        Text("Results stay sorted and ready for cleanup the moment the scan finishes.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        CleanSweepMetricTile(
                            title: "Module",
                            value: title,
                            systemImage: systemImage,
                            accent: CleanSweepPalette.accentBlue
                        )

                        CleanSweepSurface(cornerRadius: 18, padding: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Current File Path", systemImage: "folder.fill")
                                    .font(.headline)
                                Text(
                                    viewModel.currentScannedPath.isEmpty
                                        ? "Preparing scan…"
                                        : viewModel.currentScannedPath
                                )
                                    .font(.subheadline.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }

            HStack(spacing: 12) {
                ModuleFeaturePill(title: "Live Path", systemImage: "folder")
                ModuleFeaturePill(title: "Largest First", systemImage: "arrow.down.circle")
                ModuleFeaturePill(title: "Review Ready", systemImage: "checkmark.circle")
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
        }
        .padding(.vertical, 28)
    }

    private var resultsView: some View {
        VStack(spacing: 18) {
            moduleHero(
                eyebrow: "Completed",
                title: "\(title) is ready to review",
                description: "Found \(formatBytes(viewModel.totalSize)) across " +
                    "\(viewModel.results.count) item(s). Select what you want to clean."
            )

            HStack(spacing: 16) {
                ModuleMetricCard(
                    title: "Items Found",
                    value: "\(viewModel.results.count)",
                    systemImage: "doc.text.magnifyingglass",
                    accent: CleanSweepPalette.accentBlue
                )
                ModuleMetricCard(
                    title: "Selected Size",
                    value: moduleFormatBytes(viewModel.selectedSize),
                    systemImage: "checkmark.circle.fill",
                    accent: CleanSweepPalette.success
                )
                ModuleMetricCard(
                    title: "Cleanable",
                    value: formatBytes(viewModel.totalSize),
                    systemImage: "trash.fill",
                    accent: CleanSweepPalette.accentTeal
                )
            }

            CleanSweepSurface(cornerRadius: 26, padding: 12) {
                List(selection: $viewModel.selectedResultIDs) {
                    ForEach(viewModel.results) { result in
                        HStack(spacing: 12) {
                            Button {
                                viewModel.toggleSelection(for: result.id)
                            } label: {
                                Image(
                                    systemName: viewModel.selectedResultIDs.contains(result.id)
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .font(.title3)
                                .foregroundStyle(
                                    viewModel.selectedResultIDs.contains(result.id)
                                        ? CleanSweepPalette.accentBlue
                                        : .secondary
                                )
                            }
                            .buttonStyle(.plain)

                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(CleanSweepPalette.accentBlue.opacity(0.12))
                                Image(systemName: result.category.iconName)
                                    .foregroundStyle(CleanSweepPalette.accentBlue)
                                    .frame(width: 18)
                            }
                            .frame(width: 30, height: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.url.lastPathComponent)
                                    .font(.body.weight(.medium))
                                Text(result.category.localizedName)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Text(result.url.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .truncationMode(.middle)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(formatBytes(result.size))
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .tag(result.id)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.inset)
                .frame(minHeight: 320)
                .scrollContentBackground(.hidden)
            }

            if viewModel.failedCleanupCount > 0 {
                Text("\(viewModel.failedCleanupCount) item(s) could not be moved to Trash.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(viewModel.isCleaningSelection ? "Cleaning…" : cleanButtonTitle) {
                cleanTriggered.toggle()
                Task { await viewModel.cleanSelected() }
            }
            .buttonStyle(CleanSweepPrimaryButtonStyle())
            .disabled(viewModel.selectedResultIDs.isEmpty || viewModel.isCleaningSelection)
            .sensoryFeedback(
                .impact(flexibility: .rigid, intensity: 1.0),
                trigger: cleanTriggered
            )
        }
        .padding(28)
    }

    private var cleanButtonTitle: String {
        let selectedCount = viewModel.selectedResultIDs.count
        return selectedCount == 1 ? "Clean Selected Item" : "Clean Selected (\(selectedCount))"
    }

    private func formatBytes(_ bytes: Int64) -> String {
        moduleFormatBytes(bytes)
    }

    private func moduleHero(eyebrow: String, title: String, description: String) -> some View {
        CleanSweepSurface(cornerRadius: 26, padding: 28) {
            HStack(spacing: 24) {
                CleanSweepHeroIcon(systemImage: systemImage, size: 104)

                VStack(alignment: .leading, spacing: 14) {
                    CleanSweepSectionEyebrow(title: eyebrow)
                    Text(title)
                        .font(.system(size: 34, weight: .bold))
                    Text(description)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    if viewModel.phase == .idle {
                        Button {
                            scanTriggered.toggle()
                            Task { await viewModel.startScan() }
                        } label: {
                            Label("Start \(title)", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(CleanSweepPrimaryButtonStyle())
                        .sensoryFeedback(
                            .impact(flexibility: .solid, intensity: 1.0),
                            trigger: scanTriggered
                        )
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }
}

@available(macOS 26.0, *)
private struct ModuleMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let accent: Color

    var body: some View {
        CleanSweepSurface(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accent.opacity(0.14))
                        Image(systemName: systemImage)
                            .foregroundStyle(accent)
                            .font(.title3)
                    }
                    .frame(width: 42, height: 42)
                    Spacer()
                }

                Text(value)
                    .font(.title2.bold().monospacedDigit())
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(macOS 26.0, *)
private struct ModuleFeaturePill: View {
    let title: String
    let systemImage: String

    var body: some View {
        CleanSweepTag(title: title, systemImage: systemImage)
    }
}

private func moduleFormatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}
