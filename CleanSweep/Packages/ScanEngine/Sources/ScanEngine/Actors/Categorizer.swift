import Foundation

public struct Categorizer: Sendable {
    public init() {}

    // Returns nil if the file does not match any cleanable category
    public func category(for url: URL, attributes: URLResourceValues) -> FileCategory? {
        let path = url.path

        if path.contains("/DerivedData") { return .xcodeDerivedData }
        if path.contains("/CoreSimulator/Devices") { return .xcodeSimulator }
        if path.contains("/Xcode/Archives") { return .xcodeDerivedData }
        if path.contains("/SourcePackages") || path.contains("org.swift.swiftpm") { return .spmCache }
        if path.contains("/CocoaPods") || path.contains("CarthageKit") { return .spmCache }
        if url.pathExtension == "log" { return .systemLog }
        if path.contains("/Caches/") { return .userCache }
        if path.contains("/TemporaryItems/") { return .tempFile }
        if url.pathExtension == "png" || url.pathExtension == "jpg" || url.pathExtension == "jpeg" {
            if path.contains("/Desktop") || path.contains("/Downloads") {
                return .screenshot
            }
        }

        return nil
    }

    public func severity(for result: ScanResult) -> Severity {
        // High severity: Large files (> 500MB) or very old files (> 90 days)
        if result.size > 500 * 1024 * 1024 {
            return .high
        }

        if let modDate = result.lastModified {
            let daysSinceMod = Calendar.current.dateComponents([.day], from: modDate, to: Date()).day ?? 0
            if daysSinceMod > 90 {
                return .high
            }
            if daysSinceMod > 30 {
                return .medium
            }
        }

        // Medium severity: Medium files (> 100MB) or cache/log files
        if result.size > 100 * 1024 * 1024 {
            return .medium
        }

        if result.category == .userCache || result.category == .systemLog || result.category == .tempFile {
            return .medium
        }

        return .low
    }

    public func isSafeToDelete(for result: ScanResult) -> Bool {
        switch result.category {
        case .userCache, .systemLog, .tempFile, .languagePack, .browserCache, .networkCache, .trashItem:
            return true
        case .xcodeDerivedData, .xcodeSimulator, .spmCache:
            return true
        case .mailAttachment, .appSupportOrphan, .largeFile, .oldFile, .duplicate, .screenshot, .screenRecording, .fontDuplicate, .application, .startupItem, .unknown:
            return false
        }
    }
}
