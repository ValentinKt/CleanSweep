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
    case privacy
    case uninstaller
    case startup
    case memory
    case disk
    case trash
    
    var id: String { rawValue }
}
