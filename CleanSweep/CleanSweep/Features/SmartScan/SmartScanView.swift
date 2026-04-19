import SwiftUI
import ScanEngine

struct SmartScanView: View {
    @Bindable var viewModel: SmartScanViewModel
    @Binding var selection: SidebarItem?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scanStarted = false

    init(viewModel: SmartScanViewModel, selection: Binding<SidebarItem?>) {
        self.viewModel = viewModel
        self._selection = selection
    }

    var body: some View {
        ScrollView {
            switch viewModel.phase {
            case .idle:
                idleView
            case .scanning:
                scanningView
            case .complete:
                summaryView
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.phase == .complete)
    }

    private var idleView: some View {
        VStack(spacing: 24) {
            heroSection(
                eyebrow: "Smart Care",
                title: "Scan your Mac with the same calm, premium flow users expect from top-tier cleanup apps.",
                description: "Review junk, duplicates, attachments, privacy traces, and startup clutter " +
                    "with one polished pass."
            )

            HStack(spacing: 16) {
                CleanSweepMetricTile(
                    title: "Cleanup",
                    value: "Pending",
                    systemImage: "sparkles",
                    accent: CleanSweepPalette.iconBg
                )
                CleanSweepMetricTile(
                    title: "Protection",
                    value: "Pending",
                    systemImage: "shield.lefthalf.filled",
                    accent: CleanSweepPalette.accentPurple
                )
                CleanSweepMetricTile(
                    title: "Safety",
                    value: "Review First",
                    systemImage: "checkmark.shield.fill",
                    accent: CleanSweepPalette.success
                )
            }

            CleanSweepSurface(cornerRadius: 24, padding: 22, variant: .card) {
                HStack(spacing: 12) {
                    CleanSweepTag(title: "Balanced Scan", systemImage: "sparkles")
                    CleanSweepTag(title: "Live Paths", systemImage: "folder")
                    CleanSweepTag(
                        title: "Review & Route",
                        systemImage: "arrowshape.turn.up.right.fill"
                    )
                    Spacer()
                }
            }
        }
        .padding(28)
    }

    private var scanningView: some View {
        VStack(spacing: 24) {
            CleanSweepSurface(cornerRadius: 32, padding: 32, variant: .panel) {
                HStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))

                        CleanSweepProgressRing(progress: viewModel.progress, animated: !reduceMotion)
                            .shadow(color: CleanSweepPalette.iconBg.opacity(0.6), radius: 20)

                        VStack(spacing: 4) {
                            Text("\(Int(viewModel.progress * 100))%")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("Complete")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 200, height: 200)

                    VStack(alignment: .leading, spacing: 12) {
                        CleanSweepSectionEyebrow(title: "Scanning")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CleanSweepPalette.iconBg)

                        Text("Smart Scan is reviewing your Mac")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.primary)

                        Text(activeModuleTitle)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(CleanSweepPalette.iconBg)
                            .lineLimit(1)

                        Text(
                            "Smooth progress, live module updates, and path feedback stay visible throughout the scan."
                        )
                            .font(.body)
                            .foregroundStyle(.secondary)

                        CleanSweepSurface(cornerRadius: 20, padding: 16, variant: .card) {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Currently Inspecting", systemImage: "folder.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.primary.opacity(0.9))

                                Text(
                                    viewModel.currentScannedPath.isEmpty
                                        ? "Preparing scan…"
                                        : viewModel.currentScannedPath
                                )
                                    .font(.system(.caption, design: .monospaced))
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
                CleanSweepTag(title: "Bounded CPU", systemImage: "cpu")
                CleanSweepTag(title: "Live Path", systemImage: "folder")
                CleanSweepTag(title: "Progress Memory", systemImage: "circle.hexagongrid.fill")
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 32)
    }

    private var summaryView: some View {
        VStack(spacing: 24) {
            heroSection(
                eyebrow: "Completed",
                title: "Your Mac scan is ready for review.",
                description: summaryDescription
            )

            if let summary = viewModel.summary {
                HStack(spacing: 16) {
                    CleanSweepMetricTile(
                        title: "Potential Cleanup",
                        value: formatBytes(summary.totalSize),
                        systemImage: "externaldrive.fill.badge.minus",
                        accent: CleanSweepPalette.iconBg
                    )
                    CleanSweepMetricTile(
                        title: "Items Found",
                        value: "\(summary.allResults.count)",
                        systemImage: "doc.text.magnifyingglass",
                        accent: CleanSweepPalette.accentPurple
                    )
                    CleanSweepMetricTile(
                        title: "Categories",
                        value: "\(sortedCategories(for: summary).count)",
                        systemImage: "square.grid.3x2.fill",
                        accent: CleanSweepPalette.success
                    )
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 18)], spacing: 18) {
                    ForEach(sortedCategories(for: summary), id: \.category) { item in
                        categoryCard(category: item.category, size: item.size)
                    }
                }
            }
        }
        .padding(28)
    }

    private func categoryCard(category: FileCategory, size: Int64) -> some View {
        CleanSweepSurface(cornerRadius: 22, padding: 22, variant: .card) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(CleanSweepPalette.iconBg.opacity(0.12))
                        Image(systemName: category.iconName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(CleanSweepPalette.success)
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.localizedName)
                            .font(.headline)
                        Text(formatBytes(size))
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                    }

                    Spacer()
                }

                Text("Open this category to review matching files with the same premium cleanup workflow.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Review & Clean") {
                    if let destination = destination(for: category) {
                        viewModel.prepareReview(for: destination)
                        selection = destination
                    }
                }
                .buttonStyle(CleanSweepPrimaryButtonStyle())
            }
        }
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

    private var activeModuleTitle: String {
        viewModel.activeModuleName.isEmpty ? "Preparing…" : viewModel.activeModuleName
    }

    private var summaryDescription: String {
        if let summary = viewModel.summary {
            let categoryCount = sortedCategories(for: summary).count
            return "Found \(summary.allResults.count) items across \(categoryCount) categories."
        }

        return "Ready for review."
    }

    private func heroSection(eyebrow: String, title: String, description: String) -> some View {
        CleanSweepSurface(cornerRadius: 26, padding: 28, variant: .panel) {
            HStack(spacing: 24) {
                CleanSweepHeroIcon(systemImage: "wand.and.stars.inverse", size: 112)

                VStack(alignment: .leading, spacing: 14) {
                    CleanSweepSectionEyebrow(title: eyebrow)
                    Text(title)
                        .font(.system(size: 34, weight: .bold))
                    Text(description)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    if viewModel.phase == .idle {
                        Button {
                            scanStarted.toggle()
                            Task { await viewModel.startScan() }
                        } label: {
                            Label("Start Smart Scan", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(CleanSweepPrimaryButtonStyle())
                        .sensoryFeedback(.impact(flexibility: .solid, intensity: 1.0), trigger: scanStarted)
                    }
                }

                Spacer(minLength: 0)
            }
        }
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
    SmartScanView(viewModel: SmartScanViewModel(), selection: .constant(.smartScan))
}
