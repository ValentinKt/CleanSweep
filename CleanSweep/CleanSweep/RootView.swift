//
//  RootView.swift
//  CleanSweep
//

import SwiftUI

struct RootView: View {
    @State private var selection: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            DetailView(selection: selection)
                .backgroundExtensionEffect()    // macOS 26: fills floating sidebar gap
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Scan Now", systemImage: "magnifyingglass") {
                    // TODO: Trigger Scan
                }
                .buttonStyle(.glassProminent)           // accent-tinted glass (macOS 26+)
            }
            ToolbarItem(placement: .status) {
                Text("Ready to Scan")
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
