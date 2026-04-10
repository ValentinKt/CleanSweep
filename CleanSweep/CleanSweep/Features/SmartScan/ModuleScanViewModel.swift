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
    private var scanTask: Task<Void, Never>?

    public init(scanner: ModuleScanner, moduleName: String) {
        self.scanner = scanner
        self.moduleName = moduleName
    }

    public func startScan() async {
        scanTask?.cancel()
        phase = .scanning
        results.removeAll()

        scanTask = Task {
            do {
                let result = try await scanner.scan()
                if Task.isCancelled { return }
                self.results = result.results
                self.progress = 1.0
                self.phase = .complete
            } catch {
                if Task.isCancelled { return }
                print("Scan failed for \(moduleName): \(error)")
                self.phase = .idle
            }
        }
        await scanTask?.value
    }
    
    public func cancelScan() {
        scanTask?.cancel()
        phase = .idle
        progress = 0
    }

    public var totalSize: Int64 {
        results.reduce(0) { $0 + $1.size }
    }
}
