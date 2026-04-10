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
        Button(action: {
            Task { await viewModel.startScan() }
        }) {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                Text("Scan \(viewModel.moduleName)")
                    .font(.headline)
            }
            .padding(40)
        }
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
                        .trim(from: 0, to: viewModel.progress > 0 ? viewModel.progress : 0.05) // Just a spinner if progress not detailed
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: viewModel.progress)
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
                    Text("Recoverable: \(formatBytes(viewModel.totalSize))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding()
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            }

            List(viewModel.results, id: \.id) { result in
                HStack {
                    Image(systemName: "doc")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading) {
                        Text(result.url.lastPathComponent)
                            .font(.body)
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
            }
            .listStyle(.inset)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            Button("Clean Selected") {
                // Implement clean logic
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
