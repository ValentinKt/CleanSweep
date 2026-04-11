import Foundation

public protocol ModuleScanner: Sendable {
    func scan() async throws -> ModuleResult
}

public extension ModuleScanner {
    nonisolated func publishScanPath(_ path: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name("ScanPathUpdated"),
            object: path
        )
    }
}
