//
//  RootView.swift
//  CleanSweep
//

import SwiftUI

struct RootView: View {
    @State private var selection: SidebarItem? = .dashboard
    @State private var smartScanViewModel = SmartScanViewModel()

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
        } detail: {
            DetailView(selection: $selection, smartScanViewModel: smartScanViewModel)
                .backgroundExtensionEffect()    // macOS 26: fills floating sidebar gap
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
                .buttonStyle(.glassProminent)
            }
            ToolbarItem(placement: .status) {
                Text(statusText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: 250)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            ToolbarItem(placement: .automatic) {
                Button("Settings", systemImage: "gear") { }
                    .buttonStyle(.glass)
            }
        }
    }
}

#Preview {
    RootView()
}
