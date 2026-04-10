import Foundation
import ScanEngine

@MainActor
@Observable
public final class ModuleScanViewModel {
    public var results: [ScanResult] = []
    public var selectedResultIDs: Set<ScanResult.ID> = []
    public var progress: Double = 0
    public var phase: ScanPhase = .idle
    public var isCleaningSelection = false
    public var failedCleanupCount = 0
    public var moduleName: String

    private let scanner: ModuleScanner
    private var scanTask: Task<Void, Never>?

    public init(
        scanner: ModuleScanner,
        moduleName: String,
        initialResults: [ScanResult] = []
    ) {
        self.scanner = scanner
        self.moduleName = moduleName
        if !initialResults.isEmpty {
            self.results = sortedResults(from: initialResults)
            self.progress = 1.0
            self.phase = .complete
        }
    }

    public func startScan() async {
        scanTask?.cancel()
        phase = .scanning
        progress = 0
        selectedResultIDs.removeAll()
        failedCleanupCount = 0
        results.removeAll()

        scanTask = Task {
            do {
                let result = try await scanner.scan()
                if Task.isCancelled { return }
                self.results = self.sortedResults(from: result.results)
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
        selectedResultIDs.removeAll()
        isCleaningSelection = false
    }

    public var totalSize: Int64 {
        results.reduce(0) { $0 + $1.size }
    }

    public var selectedSize: Int64 {
        results.reduce(into: 0) { partialResult, result in
            guard selectedResultIDs.contains(result.id) else { return }
            partialResult += result.size
        }
    }

    public func toggleSelection(for resultID: ScanResult.ID) {
        if selectedResultIDs.contains(resultID) {
            selectedResultIDs.remove(resultID)
        } else {
            selectedResultIDs.insert(resultID)
        }
    }

    public func cleanSelected() async {
        let selectedResults = results.filter { selectedResultIDs.contains($0.id) }
        guard !selectedResults.isEmpty, !isCleaningSelection else { return }

        isCleaningSelection = true
        failedCleanupCount = 0

        let cleanupOutcome = await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            var removedIDs = Set<ScanResult.ID>()
            var failedCount = 0

            for result in selectedResults {
                do {
                    _ = try fileManager.trashItem(at: result.url, resultingItemURL: nil)
                    removedIDs.insert(result.id)
                } catch {
                    failedCount += 1
                }
            }

            return CleanupOutcome(removedIDs: removedIDs, failedCount: failedCount)
        }.value

        results.removeAll { cleanupOutcome.removedIDs.contains($0.id) }
        selectedResultIDs.subtract(cleanupOutcome.removedIDs)
        failedCleanupCount = cleanupOutcome.failedCount
        isCleaningSelection = false
    }

    private func sortedResults(from results: [ScanResult]) -> [ScanResult] {
        results.sorted { lhs, rhs in
            if lhs.size != rhs.size {
                return lhs.size > rhs.size
            }

            return lhs.url.path.localizedStandardCompare(rhs.url.path) == .orderedAscending
        }
    }

    private struct CleanupOutcome: Sendable {
        let removedIDs: Set<ScanResult.ID>
        let failedCount: Int
    }
}
