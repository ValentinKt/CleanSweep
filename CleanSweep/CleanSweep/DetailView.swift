//
//  DetailView.swift
//  CleanSweep
//

import SwiftUI

struct DetailView: View {
    var selection: SidebarItem?

    var body: some View {
        Group {
            if let selection {
                switch selection {
                case .dashboard:
                    DashboardView()
                case .smartScan:
                    if #available(macOS 26.0, *) {
                        SmartScanView()
                    } else {
                        Text("Smart Scan requires macOS 26.0")
                    }
                default:
                    ContentUnavailableView(
                        "\(selection.rawValue.capitalized) Coming Soon",
                        systemImage: "hammer",
                        description: Text("This feature is under construction.")
                    )
                }
            } else {
                ContentUnavailableView("Select an item", systemImage: "sidebar.left")
            }
        }
    }
}
