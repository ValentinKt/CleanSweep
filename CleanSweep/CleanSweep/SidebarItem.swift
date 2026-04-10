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

    var id: String { rawValue }
}
