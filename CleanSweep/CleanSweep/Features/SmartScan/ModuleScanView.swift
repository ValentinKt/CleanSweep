import SwiftUI
import ScanEngine

@available(macOS 26.0, *)
public struct ModuleScanView: View {
    @State private var viewModel: ModuleScanViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassSpace

    public init(scanner: ModuleScanner, title: String) {
        _viewModel = State(initialValue: ModuleScanViewModel(scanner: scanner, moduleName: title))
    }

    public var body: some View {
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
        .navigationTitle(viewModel.moduleName)
    }

    private var idleView: some View {
        Button(
            action: {
                Task { await viewModel.startScan() }
            },
            label: {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                    Text("Scan \(viewModel.moduleName)")
                        .font(.headline)
                }
                .padding(40)
            }
        )
        .glassEffect(.regular.interactive(), in: Circle())
        .glassEffectID("moduleRing", in: glassSpace)
        .buttonStyle(.plain)
    }

    private var scanningView: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: viewModel.progress > 0 ? viewModel.progress : 0.05)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8),
                            value: viewModel.progress
                        )
                }
                .frame(width: 150, height: 150)
                .glassEffect(.regular, in: Circle())
                .glassEffectID("moduleRing", in: glassSpace)

                VStack(spacing: 8) {
                    Text("Scanning \(viewModel.moduleName)...")
                        .font(.headline)
                }
            }
        }
    }

    private var resultsView: some View {
        VStack(spacing: 16) {
            GlassEffectContainer(spacing: 16) {
                HStack {
                    Text("\(viewModel.results.count) Items Found")
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Recoverable: \(formatBytes(viewModel.totalSize))")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.secondary)

                        if !viewModel.selectedResultIDs.isEmpty {
                            Text("Selected: \(formatBytes(viewModel.selectedSize))")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .padding()
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            }

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
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            if viewModel.failedCleanupCount > 0 {
                Text("\(viewModel.failedCleanupCount) item(s) could not be moved to Trash.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(viewModel.isCleaningSelection ? "Cleaning…" : cleanButtonTitle) {
                Task { await viewModel.cleanSelected() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.selectedResultIDs.isEmpty || viewModel.isCleaningSelection)
        }
    }

    private var cleanButtonTitle: String {
        let selectedCount = viewModel.selectedResultIDs.count
        return selectedCount == 1 ? "Clean Selected Item" : "Clean Selected (\(selectedCount))"
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
