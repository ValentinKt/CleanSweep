import SwiftUI
import ScanEngine

struct ModuleScanHighlight: Hashable {
    let title: String
    let systemImage: String
}

@available(macOS 26.0, *)
private struct FolderRowView: View {
    let path: String
    let files: [ScanResult]
    @Bindable var viewModel: ModuleScanViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.toggleFolderExpansion(path)
            } label: {
                Image(systemName: viewModel.expandedFolders.contains(path) ? "chevron.down" : "chevron.right")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 12)
            }
            .buttonStyle(.plain)

            Image(systemName: viewModel.isFolderSelected(path) ? "checkmark.square.fill" : "square")
                .font(.title3)
                .foregroundStyle(viewModel.isFolderSelected(path) ? CleanSweepPalette.iconBg : .secondary)
                .onTapGesture {
                    viewModel.toggleFolderSelection(path)
                }

            Image(systemName: "folder.fill")
                .foregroundStyle(CleanSweepPalette.accentBlue.opacity(0.8))

            VStack(alignment: .leading, spacing: 2) {
                Text(path)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(files.count) files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(moduleFormatBytes(files.reduce(0) { $0 + $1.size }))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .listRowBackground(Color.clear)
    }
}

@available(macOS 26.0, *)
private struct ScanResultRowView: View {
    let result: ScanResult
    @Bindable var viewModel: ModuleScanViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(
                systemName: viewModel.selectedResultIDs.contains(result.id)
                    ? "checkmark.square.fill"
                    : "square"
            )
            .font(.title3)
            .foregroundStyle(
                viewModel.selectedResultIDs.contains(result.id)
                    ? CleanSweepPalette.iconBg
                    : .secondary
            )

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(CleanSweepPalette.iconBg.opacity(0.12))
                Image(systemName: result.category.iconName)
                    .foregroundStyle(CleanSweepPalette.iconBg)
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

            if let severity = result.severity {
                Text(severity.localizedName)
                    .font(.caption2.weight(.bold).uppercaseSmallCaps())
                    .foregroundStyle(severityColor(for: severity))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor(for: severity).opacity(0.15), in: Capsule())
                    .padding(.trailing, 4)
            }

            Text(moduleFormatBytes(result.size))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .cleanSweepGlass(
                    in: Capsule(),
                    material: .menu,
                    tint: Color.white.opacity(0.08),
                    bandOpacity: 0.55,
                    borderOpacity: 0.16
                )
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleSelection(for: result.id)
        }
        .tag(result.id)
        .listRowBackground(Color.clear)
        .contextMenu {
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([result.url])
            }
        }
    }

    private func severityColor(for severity: Severity) -> Color {
        switch severity {
        case .high: return CleanSweepPalette.error
        case .medium: return CleanSweepPalette.warning
        case .low: return CleanSweepPalette.success
        }
    }
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
            Group {
                switch viewModel.phase {
                case .idle:
                    idleView
                case .scanning:
                    scanningView
                case .complete:
                    resultsView
                }
            }
            .padding(28)
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
                    value: "\(viewModel.filteredResults.count)",
                    systemImage: "doc.text.magnifyingglass",
                    accent: CleanSweepPalette.iconBg
                )
                ModuleMetricCard(
                    title: "Selected Size",
                    value: moduleFormatBytes(viewModel.selectedSize),
                    systemImage: "checkmark.circle.fill",
                    accent: CleanSweepPalette.iconBg
                )
                ModuleMetricCard(
                    title: "Cleanable",
                    value: formatBytes(viewModel.totalSize),
                    systemImage: "trash.fill",
                    accent: CleanSweepPalette.iconBg
                )
            }

            // Tabs and Filter Bar
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("View")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)

                    Button("Safe to Clean") { viewModel.showOnlySafeToDelete = true }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(activeTabBackground(isActive: viewModel.showOnlySafeToDelete))
                        .foregroundStyle(viewModel.showOnlySafeToDelete ? .white : .secondary)
                        .contentShape(Capsule())

                    Button("All Files") { viewModel.showOnlySafeToDelete = false }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(activeTabBackground(isActive: !viewModel.showOnlySafeToDelete))
                        .foregroundStyle(!viewModel.showOnlySafeToDelete ? .white : .secondary)
                        .contentShape(Capsule())
                }
                .padding(4)
                .background {
                    Capsule(style: .continuous)
                        .cleanSweepGlass(
                            in: Capsule(style: .continuous),
                            material: .menu,
                            tint: Color.white.opacity(0.05),
                            bandOpacity: 0.55,
                            borderOpacity: 0.14
                        )
                }

                Spacer()

                Menu {
                    Button {
                        viewModel.selectedSeverity = nil
                    } label: {
                        HStack {
                            Text("All Severities")
                            if viewModel.selectedSeverity == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Divider()

                    ForEach([Severity.high, .medium, .low], id: \.self) { severity in
                        Button {
                            viewModel.selectedSeverity = severity
                        } label: {
                            HStack {
                                Text(severity.localizedName)
                                if viewModel.selectedSeverity == severity {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "face.smiling")
                            .foregroundStyle(CleanSweepPalette.iconBg)
                        Text(viewModel.selectedSeverity?.localizedName ?? "Filter by Severity")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .cleanSweepGlass(
                        in: Capsule(),
                        material: .menu,
                        tint: Color.white.opacity(0.06),
                        showIridescence: true,
                        bandOpacity: 0.7,
                        borderOpacity: 0.2
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 12)

            CleanSweepSurface(cornerRadius: 26, padding: 12) {
                VStack(spacing: 0) {
                    listHeader

                    Divider()
                        .padding(.horizontal, 16)
                        .opacity(0.5)

                    List {
                        ForEach(viewModel.sortedFolderPaths, id: \.self) { path in
                            let files = viewModel.groupedResults[path] ?? []
                            FolderRowView(path: path, files: files, viewModel: viewModel)

                            if viewModel.expandedFolders.contains(path) {
                                ForEach(files) { result in
                                    ScanResultRowView(result: result, viewModel: viewModel)
                                        .padding(.leading, 36)
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                    .frame(minHeight: 320)
                    .scrollContentBackground(.hidden)
                }
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
    }

    private var cleanButtonTitle: String {
        let selectedCount = viewModel.selectedResultIDs.count
        return selectedCount == 1 ? "Clean Selected Item" : "Clean Selected (\(selectedCount))"
    }

    @ViewBuilder
    private func activeTabBackground(isActive: Bool) -> some View {
        if isActive {
            Capsule(style: .continuous)
                .fill(CleanSweepPalette.iconBg)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
    }

    private var listHeader: some View {
        HStack {
            Button {
                viewModel.toggleSelectAll()
            } label: {
                HStack(spacing: 8) {
                    Image(
                        systemName: viewModel.isAllSelected
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .font(.title3)
                    .foregroundStyle(
                        viewModel.isAllSelected
                            ? CleanSweepPalette.iconBg
                            : .secondary
                    )
                    Text(viewModel.isAllSelected ? "Deselect All" : "Select All")
                        .font(.body.weight(.medium))
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleSelectAll()
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        moduleFormatBytes(bytes)
    }

    private func severityColor(for severity: Severity) -> Color {
        switch severity {
        case .high: return CleanSweepPalette.error
        case .medium: return CleanSweepPalette.warning
        case .low: return CleanSweepPalette.success
        }
    }

    private func moduleHero(eyebrow: String, title: String, description: String) -> some View {
        CleanSweepSurface(cornerRadius: 26, padding: 28) {
            HStack(spacing: 24) {
                CleanSweepHeroIcon(systemImage: systemImage, size: 104)
                    .background {
                        RoundedRectangle(cornerRadius: 104 * 0.28, style: .continuous)
                            .fill(CleanSweepPalette.iconBg)
                            .blur(radius: 20)
                            .opacity(0.6)
                            .offset(y: 8)
                    }

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
