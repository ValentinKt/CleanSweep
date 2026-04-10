import Foundation

public struct ModuleResult: Sendable {
    public let moduleName: String
    public let results: [ScanResult]
    public let totalSize: Int64

    public init(moduleName: String, results: [ScanResult]) {
        self.moduleName = moduleName
        self.results = results
        self.totalSize = results.reduce(0) { $0 + $1.size }
    }
}
