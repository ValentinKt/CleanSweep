import Foundation

public protocol ModuleScanner: Sendable {
    func scan() async throws -> ModuleResult
}
