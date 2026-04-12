import Foundation

public enum Severity: Int, Comparable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    public var localizedName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    public static func < (lhs: Severity, rhs: Severity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public struct ScanResult: Sendable, Identifiable, Hashable {
    public let id = UUID()
    public let url: URL
    public let size: Int64
    public let category: FileCategory
    public let lastModified: Date?
    public let creationDate: Date?
    public let appName: String? // Resolved from bundle ID
    public let severity: Severity?
    public let isSafeToDelete: Bool

    public init(
        url: URL,
        size: Int64,
        category: FileCategory,
        lastModified: Date? = nil,
        creationDate: Date? = nil,
        appName: String? = nil,
        severity: Severity? = nil,
        isSafeToDelete: Bool = true
    ) {
        self.url = url
        self.size = size
        self.category = category
        self.lastModified = lastModified
        self.creationDate = creationDate
        self.appName = appName
        self.severity = severity
        self.isSafeToDelete = isSafeToDelete
    }
}
