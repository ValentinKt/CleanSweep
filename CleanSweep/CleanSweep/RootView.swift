//
//  RootView.swift
//  CleanSweep
//

import SwiftUI

@available(macOS 26.0, *)
struct RootView: View {
    @State private var selection: SidebarItem? = .dashboard
    @State private var smartScanViewModel = SmartScanViewModel()
    @State private var moduleSessionStore = ModuleScanSessionStore()

    var statusText: String {
        switch smartScanViewModel.phase {
        case .idle: return "Ready to Scan"
        case .scanning: return "Scanning: \(smartScanViewModel.activeModuleName)"
        case .complete: return "Scan Complete"
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 340)
        } detail: {
            DetailView(
                selection: $selection,
                smartScanViewModel: smartScanViewModel,
                moduleSessionStore: moduleSessionStore
            )
                .backgroundExtensionEffect()
        }
        .navigationSplitViewStyle(.balanced)
        .background {
            CleanSweepWindowBackground()
        }
        .tint(CleanSweepPalette.accentBlue)
        .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack(spacing: 12) {
                        CleanSweepHeroIcon(systemImage: "bubbles.and.sparkles", size: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CleanSweep")
                                .font(.headline.weight(.semibold))
                            Text("Mac Health Suite")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        selection = .smartScan
                        if smartScanViewModel.phase == .scanning {
                            smartScanViewModel.cancelScan()
                        } else {
                            Task { await smartScanViewModel.startScan() }
                        }
                    } label: {
                        Label(
                            smartScanViewModel.phase == .scanning ? "Cancel Scan" : "Scan Now",
                            systemImage: smartScanViewModel.phase == .scanning ? "stop.circle.fill" : "magnifyingglass"
                        )
                    }
                    .buttonStyle(CleanSweepPrimaryButtonStyle())

                    Text(statusText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.001))
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        }

                    Button("Settings", systemImage: "gearshape.fill") { }
                        .buttonStyle(CleanSweepSecondaryButtonStyle())
                }
            }
    }
}

#Preview {
    if #available(macOS 26.0, *) {
        RootView()
    }
}
