import Foundation

public enum FileCategory: String, CaseIterable, Sendable {
    case userCache
    case systemLog
    case tempFile
    case languagePack
    case xcodeDerivedData
    case xcodeSimulator
    case spmCache
    case mailAttachment
    case browserCache
    case appSupportOrphan
    case largeFile
    case oldFile
    case duplicate
    case screenshot
    case screenRecording
    case fontDuplicate
    case trashItem
    case networkCache
    case application
    case startupItem
    case unknown

    public var localizedName: String {
        switch self {
        case .userCache: return "User Caches"
        case .systemLog: return "System Logs"
        case .tempFile: return "Temporary Files"
        case .languagePack: return "Language Packs"
        case .xcodeDerivedData: return "Xcode Derived Data"
        case .xcodeSimulator: return "Xcode Simulators"
        case .spmCache: return "SwiftPM Caches"
        case .mailAttachment: return "Mail Attachments"
        case .browserCache: return "Browser Caches"
        case .appSupportOrphan: return "App Support Orphans"
        case .largeFile: return "Large Files"
        case .oldFile: return "Old Files"
        case .duplicate: return "Duplicates"
        case .screenshot: return "Screenshots"
        case .screenRecording: return "Screen Recordings"
        case .fontDuplicate: return "Font Duplicates"
        case .trashItem: return "Trash"
        case .networkCache: return "Network Caches"
        case .application: return "Applications"
        case .startupItem: return "Startup Items"
        case .unknown: return "Unknown"
        }
    }

    public var iconName: String {
        switch self {
        case .userCache: return "cylinder.split.1x2"
        case .systemLog: return "doc.text"
        case .tempFile: return "clock.arrow.circlepath"
        case .languagePack: return "character.bubble"
        case .xcodeDerivedData: return "hammer"
        case .xcodeSimulator: return "iphone"
        case .spmCache: return "shippingbox"
        case .mailAttachment: return "paperclip"
        case .browserCache: return "safari"
        case .appSupportOrphan: return "questionmark.folder"
        case .largeFile: return "externaldrive"
        case .oldFile: return "calendar.badge.clock"
        case .duplicate: return "doc.on.doc"
        case .screenshot: return "camera.viewfinder"
        case .screenRecording: return "video"
        case .fontDuplicate: return "textformat"
        case .trashItem: return "trash"
        case .networkCache: return "network"
        case .application: return "app.badge"
        case .startupItem: return "macwindow"
        case .unknown: return "doc"
        }
    }
}
