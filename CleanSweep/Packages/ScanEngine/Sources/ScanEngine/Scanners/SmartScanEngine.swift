import Foundation

public actor SmartScanEngine {
    public init() {}

    public func scanAllModules() async throws -> ScanSummary {
        try await withThrowingTaskGroup(of: ModuleResult.self) { group in
            group.addTask { try await SystemJunkScanner().scan() }
            // More scanners can be added here

            var summary = ScanSummary()
            for try await result in group {
                summary.merge(result)
            }
            return summary
        }
    }
}
