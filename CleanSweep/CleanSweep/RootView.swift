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
                Button("Scan Now", systemImage: "magnifyingglass") {
                    selection = .smartScan
                    Task { await smartScanViewModel.startScan() }
                }
                .buttonStyle(.glassProminent)           // accent-tinted glass (macOS 26+)
            }
            ToolbarItem(placement: .status) {
                Text(statusText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: 250)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
            }
            ToolbarItem(placement: .automatic) {
                Button("Settings", systemImage: "gear") { }
            }
        }
    }
}

#Preview {
    RootView()
}
