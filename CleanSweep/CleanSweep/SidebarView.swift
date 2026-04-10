//
//  SidebarView.swift
//  CleanSweep
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            Section("Overview") {
                SidebarRow(item: .dashboard, symbol: "gauge.medium", label: "Dashboard")
                SidebarRow(item: .smartScan, symbol: "sparkles.rectangle.stack", label: "Smart Scan")
            }
            Section("Clean") {
                SidebarRow(item: .systemJunk, symbol: "trash.slash", label: "System Junk")
                SidebarRow(item: .largeFiles, symbol: "archivebox", label: "Large & Old Files")
                SidebarRow(item: .duplicates, symbol: "doc.on.doc", label: "Duplicates")
                SidebarRow(item: .screenshots, symbol: "photo.on.rectangle", label: "Screenshots")
                SidebarRow(item: .development, symbol: "hammer", label: "Developer Junk")
                SidebarRow(item: .trash, symbol: "trash", label: "Trash")
                SidebarRow(item: .mailAttachments, symbol: "paperclip", label: "Mail Attachments")
            }
            Section("Protect") {
                SidebarRow(item: .privacy, symbol: "hand.raised", label: "Privacy")
                SidebarRow(item: .networkCache, symbol: "network", label: "Network Cache")
            }
            Section("Manage") {
                SidebarRow(item: .uninstaller, symbol: "app.badge.minus", label: "Uninstaller")
                SidebarRow(item: .startup, symbol: "bolt.fill", label: "Startup Items")
                SidebarRow(item: .memory, symbol: "memorychip", label: "Memory")
                SidebarRow(item: .disk, symbol: "externaldrive", label: "Disk Analyzer")
                SidebarRow(item: .fonts, symbol: "textformat", label: "Font Manager")
            }
        }
        .listStyle(.sidebar)
    }
}

struct SidebarRow: View {
    let item: SidebarItem
    let symbol: String
    let label: String
    var badge: String?

    var body: some View {
        NavigationLink(value: item) {
            HStack {
                Label(label, systemImage: symbol)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .glassEffect(.regular.tint(.accentColor.opacity(0.25)), in: Capsule())
                }
            }
        }
    }
}
