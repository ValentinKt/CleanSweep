import Foundation

public struct ScanSummary: Sendable {
    public private(set) var moduleResults: [String: ModuleResult] = [:]
    public private(set) var totalSizeByFileCategory: [FileCategory: Int64] = [:]
    public private(set) var allResults: [ScanResult] = []
    
    public init() {}
    
    public var totalSize: Int64 {
        allResults.reduce(0) { $0 + $1.size }
    }
    
    public mutating func merge(_ result: ModuleResult) {
        moduleResults[result.moduleName] = result
        allResults.append(contentsOf: result.results)
        
        for item in result.results {
            totalSizeByFileCategory[item.category, default: 0] += item.size
        }
    }
}
