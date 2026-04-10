//
//  RootView.swift
//  CleanSweep
//

import SwiftUI

struct RootView: View {
    @State private var selection: SidebarItem? = .dashboard
    @State private var smartScanViewModel = SmartScanViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            DetailView(selection: selection, smartScanViewModel: smartScanViewModel)
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
                Text("Ready to Scan")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
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
