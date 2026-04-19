//
//  RootView.swift
//  CleanSweep
//

import SwiftUI

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
        HStack(alignment: .top, spacing: 18) {
            SidebarView(selection: $selection)
                .frame(width: 300, alignment: .topLeading)

            DetailView(
                selection: $selection,
                smartScanViewModel: smartScanViewModel,
                moduleSessionStore: moduleSessionStore
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(16)
        .background {
            CleanSweepWindowBackground()
        }
        .overlay {
            CleanSweepWindowConfigurator()
                .allowsHitTesting(false)
        }
        .frame(minWidth: 1180, minHeight: 760, alignment: .topLeading)
        .tint(CleanSweepPalette.iconBg)
        .animation(.spring(response: 0.42, dampingFraction: 0.84), value: selection)
    }
}

#Preview {
    RootView()
}
