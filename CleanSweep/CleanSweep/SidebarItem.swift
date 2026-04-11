//
//  SidebarItem.swift
//  CleanSweep
//

import Foundation

enum SidebarItem: String, CaseIterable, Hashable, Identifiable {
    case dashboard
    case smartScan
    case systemJunk
    case largeFiles
    case duplicates
    case screenshots
    case development
    case privacy
    case uninstaller
    case startup
    case memory
    case disk
    case trash
    case networkCache
    case fonts
    case mailAttachments
    case leftovers

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .smartScan: return "Smart Scan"
        case .systemJunk: return "System Junk"
        case .largeFiles: return "Large Files"
        case .duplicates: return "Duplicates"
        case .screenshots: return "Screenshots"
        case .development: return "Developer Junk"
        case .privacy: return "Privacy"
        case .uninstaller: return "Uninstaller"
        case .startup: return "Startup Items"
        case .memory: return "Memory Monitor"
        case .disk: return "Disk Analyzer"
        case .trash: return "Trash Manager"
        case .networkCache: return "Network Cache"
        case .fonts: return "Font Manager"
        case .mailAttachments: return "Mail Attachments"
        case .leftovers: return "Leftovers"
        }
    }

    var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .smartScan: return "wand.and.stars"
        case .systemJunk: return "pc"
        case .largeFiles: return "externaldrive"
        case .duplicates: return "doc.on.doc"
        case .screenshots: return "camera.viewfinder"
        case .development: return "hammer"
        case .privacy: return "hand.raised"
        case .uninstaller: return "app.badge"
        case .startup: return "macwindow"
        case .memory: return "memorychip"
        case .disk: return "chart.pie"
        case .trash: return "trash"
        case .networkCache: return "network"
        case .fonts: return "textformat"
        case .mailAttachments: return "paperclip"
        case .leftovers: return "puzzlepiece.extension"
        }
    }
}
