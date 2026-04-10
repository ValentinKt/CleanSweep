import Foundation

public actor Categorizer {
    public init() {}

    // Returns nil if the file does not match any cleanable category
    public func category(for url: URL, attributes: URLResourceValues) -> FileCategory? {
        let path = url.path

        if path.contains("/DerivedData") { return .xcodeDerivedData }
        if path.contains("/CoreSimulator/Devices") { return .xcodeSimulator }
        if path.contains("/Xcode/Archives") { return .xcodeDerivedData } // Grouping under DerivedData or create a new one? Let's use xcodeDerivedData for now.
        if path.contains("/SourcePackages") || path.contains("org.swift.swiftpm") { return .spmCache }
        if path.contains("/CocoaPods") || path.contains("CarthageKit") { return .spmCache } // Grouping under spmCache for developer junk
        if url.pathExtension == "log" { return .systemLog }
        if path.contains("/Caches/") { return .userCache }
        if path.contains("/TemporaryItems/") { return .tempFile }

        // ... ordered from most specific to least specific
        return nil
    }
}
