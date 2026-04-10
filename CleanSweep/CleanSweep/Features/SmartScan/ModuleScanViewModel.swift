import Foundation
import ScanEngine

@MainActor
@Observable
public final class ModuleScanViewModel {
    public var results: [ScanResult] = []
    public var progress: Double = 0
    public var phase: ScanPhase = .idle
    public var moduleName: String

    private let scanner: ModuleScanner

    public init(scanner: ModuleScanner, moduleName: String) {
        self.scanner = scanner
        self.moduleName = moduleName
    }

    public func startScan() async {
        phase = .scanning
        results.removeAll()

        do {
            let result = try await scanner.scan()
            self.results = result.results
            self.progress = 1.0
            self.phase = .complete
        } catch {
            print("Scan failed for \(moduleName): \(error)")
            self.phase = .idle
        }
    }

    public var totalSize: Int64 {
        results.reduce(0) { $0 + $1.size }
    }
}
