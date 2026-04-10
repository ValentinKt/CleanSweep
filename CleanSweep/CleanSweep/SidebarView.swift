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
                SidebarRow(item: .dashboard)
                SidebarRow(item: .smartScan)
            }
            Section("Clean") {
                SidebarRow(item: .systemJunk)
                SidebarRow(item: .largeFiles)
                SidebarRow(item: .duplicates)
                SidebarRow(item: .screenshots)
                SidebarRow(item: .development)
                SidebarRow(item: .trash)
                SidebarRow(item: .mailAttachments)
            }
            Section("Protect") {
                SidebarRow(item: .privacy)
                SidebarRow(item: .networkCache)
            }
            Section("Manage") {
                SidebarRow(item: .uninstaller)
                SidebarRow(item: .startup)
                SidebarRow(item: .memory)
                SidebarRow(item: .disk)
                SidebarRow(item: .fonts)
            }
        }
        .listStyle(.sidebar)
    }
}

struct SidebarRow: View {
    let item: SidebarItem
    var badge: String?

    var body: some View {
        NavigationLink(value: item) {
            HStack {
                Label(item.localizedName, systemImage: item.iconName)
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
