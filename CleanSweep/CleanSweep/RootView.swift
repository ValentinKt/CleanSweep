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
        .overlay {
            CleanSweepWindowConfigurator()
                .allowsHitTesting(false)
        }
        .tint(CleanSweepPalette.iconBg)
    }
}

#Preview {
    if #available(macOS 26.0, *) {
        RootView()
    }
}
