//
//  DetailView.swift
//  CleanSweep
//

import SwiftUI
import ScanEngine

struct DetailView: View {
    var selection: SidebarItem?

    var body: some View {
        contentView
            .navigationTitle(selection?.rawValue.capitalized ?? "CleanSweep")
    }

    @ViewBuilder
    private var contentView: some View {
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
            case .systemJunk:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: SystemJunkScanner(), title: "System Junk")
                } else {
                    Text("System Junk requires macOS 26.0")
                }
            case .development:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: DevelopmentJunkScanner(), title: "Developer Junk")
                } else {
                    Text("Developer Junk requires macOS 26.0")
                }
            case .largeFiles:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: LargeFilesScanner(), title: "Large & Old Files")
                } else {
                    Text("Large & Old Files requires macOS 26.0")
                }
            case .screenshots:
                if #available(macOS 26.0, *) {
                    ModuleScanView(scanner: ScreenshotScanner(), title: "Screenshots & Recordings")
                } else {
                    Text("Screenshots requires macOS 26.0")
                }
            default:
                ContentUnavailableView(
                    "\(selection.rawValue.capitalized)",
                    systemImage: "hammer.fill",
                    description: Text("This feature is under construction.")
                )
            }
        } else {
            ContentUnavailableView("Select an item", systemImage: "sidebar.left")
        }
    }
}
