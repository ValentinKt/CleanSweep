import Foundation

public actor Categorizer {
    public init() {}

    // Returns nil if the file does not match any cleanable category
    public func category(for url: URL, attributes: URLResourceValues) -> FileCategory? {
        let path = url.path

        if path.contains("/DerivedData") { return .xcodeDerivedData }
        if path.contains("/CoreSimulator/Devices") { return .xcodeSimulator }
        if path.contains("/SourcePackages") { return .spmCache }
        if url.pathExtension == "log" { return .systemLog }
        if path.contains("/Caches/") { return .userCache }
        if path.contains("/TemporaryItems/") { return .tempFile }

        // ... ordered from most specific to least specific
        return nil
    }
}
