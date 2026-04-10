import Foundation

public struct ScanResult: Sendable, Identifiable, Hashable {
    public let id = UUID()
    public let url: URL
    public let size: Int64
    public let category: FileCategory
    public let lastModified: Date?
    public let creationDate: Date?
    public let appName: String? // Resolved from bundle ID

    public init(url: URL, size: Int64, category: FileCategory, lastModified: Date? = nil, creationDate: Date? = nil, appName: String? = nil) {
        self.url = url
        self.size = size
        self.category = category
        self.lastModified = lastModified
        self.creationDate = creationDate
        self.appName = appName
    }
}
