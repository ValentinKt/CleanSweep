import SwiftUI
import ScanEngine

struct ModuleScanHighlight: Hashable {
    let title: String
    let systemImage: String
}

@available(macOS 26.0, *)
struct ModuleScanView: View {
    @State private var viewModel: ModuleScanViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassSpace
    private let title: String
    private let systemImage: String
    private let descriptionText: String
    private let highlights: [ModuleScanHighlight]
    @State private var scanTriggered = false
    @State private var cleanTriggered = false

    init(
        scanner: ModuleScanner,
        title: String,
        systemImage: String,
        descriptionText: String,
        highlights: [ModuleScanHighlight]
    ) {
        _viewModel = State(initialValue: ModuleScanViewModel(scanner: scanner, moduleName: title))
        self.title = title
        self.systemImage = systemImage
        self.descriptionText = descriptionText
        self.highlights = highlights
    }

    var body: some View {
        VStack {
            switch viewModel.phase {
            case .idle:
                idleView
            case .scanning:
                scanningView
            case .complete:
                resultsView
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
        .sensoryFeedback(.success, trigger: viewModel.phase == .complete)
    }

    private var idleView: some View {
        GlassEffectContainer(spacing: 18) {
            VStack(spacing: 24) {
                Image(systemName: systemImage)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                VStack(spacing: 10) {
                    Text(title)
                        .font(.largeTitle.bold())

                    Text(descriptionText)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 560)
                }

                Button {
                    scanTriggered.toggle()
                    Task { await viewModel.startScan() }
                } label: {
                    Label("Start \(title)", systemImage: "magnifyingglass")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }
                .glassEffect(.regular.interactive(), in: Capsule())
                .glassEffectID("moduleRing", in: glassSpace)
                .buttonStyle(.plain)
                .sensoryFeedback(
                    .impact(flexibility: .solid, intensity: 1.0),
                    trigger: scanTriggered
                )

                if !highlights.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(highlights, id: \.self) { highlight in
                            ModuleFeaturePill(title: highlight.title, systemImage: highlight.systemImage)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(32)
            .frame(maxWidth: 680)
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
                        .trim(from: 0, to: viewModel.progress > 0 ? viewModel.progress : 0.08)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8),
                            value: viewModel.progress
                        )

                    Text(viewModel.progress > 0 ? "\(Int(viewModel.progress * 100))%" : "…")
                        .font(.largeTitle.bold().monospacedDigit())
                }
                .frame(width: 200, height: 200)
                .glassEffect(.regular, in: Circle())
                .glassEffectID("moduleRing", in: glassSpace)

                VStack(spacing: 16) {
                    Text("Scanning")
                        .font(.headline)

                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: 320)

                    Text("Preparing a size-ranked review with selectable cleanup targets.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: 460)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                HStack(spacing: 12) {
                    ModuleFeaturePill(title: "Largest First", systemImage: "arrow.down")
                    ModuleFeaturePill(title: "Selectable", systemImage: "checkmark.circle")
                    ModuleFeaturePill(title: "Review Ready", systemImage: "arrow.right.circle")
                }
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
    }

    private var resultsView: some View {
        VStack(spacing: 16) {
            GlassEffectContainer(spacing: 16) {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("Scan Complete")
                            .font(.largeTitle.bold())
                        Text("Found \(formatBytes(viewModel.totalSize)) ready to review")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 18)
                    .glassEffect(.regular, in: Capsule())
                    .glassEffectID("moduleRing", in: glassSpace)

                    HStack(spacing: 16) {
                        ModuleMetricCard(
                            title: "Items Found",
                            value: "\(viewModel.results.count)",
                            systemImage: "doc.text.magnifyingglass"
                        )

                        ModuleMetricCard(
                            title: "Selected Size",
                            value: moduleFormatBytes(viewModel.selectedSize),
                            systemImage: "checkmark.circle"
                        )
                    }

                    HStack(spacing: 12) {
                        ModuleFeaturePill(title: "Largest First", systemImage: "arrow.down.circle")
                        ModuleFeaturePill(title: "Select to Clean", systemImage: "checklist")
                        ModuleFeaturePill(title: "Trash Safe", systemImage: "trash")
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            GlassEffectContainer(spacing: 16) {
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
                                        ? Color.accentColor
                                        : .secondary
                                )
                            }
                            .buttonStyle(.plain)

                            Image(systemName: result.category.iconName)
                                .foregroundStyle(.secondary)
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.url.lastPathComponent)
                                    .font(.body)
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
                    }
                }
                .listStyle(.inset)
                .frame(minHeight: 320)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
            .buttonStyle(.glassProminent)
            .disabled(viewModel.selectedResultIDs.isEmpty || viewModel.isCleaningSelection)
            .sensoryFeedback(
                .impact(flexibility: .rigid, intensity: 1.0),
                trigger: cleanTriggered
            )
        }
        .transition(.blurReplace)
    }

    private var cleanButtonTitle: String {
        let selectedCount = viewModel.selectedResultIDs.count
        return selectedCount == 1 ? "Clean Selected Item" : "Clean Selected (\(selectedCount))"
    }

    private func formatBytes(_ bytes: Int64) -> String {
        moduleFormatBytes(bytes)
    }
}

@available(macOS 26.0, *)
private struct ModuleMetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
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
}

@available(macOS 26.0, *)
private struct ModuleFeaturePill: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: Capsule())
    }
}

private func moduleFormatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}
