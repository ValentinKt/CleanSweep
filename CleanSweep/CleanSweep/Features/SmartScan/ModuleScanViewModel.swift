import Foundation
import Observation
import ScanEngine

@MainActor
@Observable
public final class ModuleScanViewModel {
    public var results: [ScanResult] = []
    public var selectedResultIDs: Set<ScanResult.ID> = []
    public var selectedSeverity: Severity?
    public var showOnlySafeToDelete = true
    public var progress: Double = 0
    public var phase: ScanPhase = .idle
    public var isCleaningSelection = false
    public var failedCleanupCount = 0
    public var moduleName: String
    public var currentScannedPath: String = ""

    public var filteredResults: [ScanResult] {
        results.filter { result in
            let matchesSeverity = selectedSeverity == nil || result.severity == selectedSeverity
            let matchesSafe = !showOnlySafeToDelete || result.isSafeToDelete
            return matchesSeverity && matchesSafe
        }
    }

    private let scanPathUpdatedNotification = NSNotification.Name("ScanPathUpdated")
    private let minimumPathUpdateInterval = Duration.milliseconds(150)
    private let minimumScanPresentationDuration = Duration.seconds(1)
    private let scanner: ModuleScanner
    private var scanTask: Task<Void, Never>?
    private var pathUpdateTask: Task<Void, Never>?
    private var progressPulseTask: Task<Void, Never>?

    public init(
        scanner: ModuleScanner,
        moduleName: String,
        initialResults: [ScanResult] = []
    ) {
        self.scanner = scanner
        self.moduleName = moduleName
        if !initialResults.isEmpty {
            applySeedResults(initialResults)
        }
    }

    public func applySeedResults(_ initialResults: [ScanResult]) {
        guard !initialResults.isEmpty else { return }
        scanTask?.cancel()
        pathUpdateTask?.cancel()
        progressPulseTask?.cancel()
        results = sortedResults(from: initialResults)
        selectedResultIDs.removeAll()
        progress = 1.0
        phase = .complete
        currentScannedPath = ""
    }

    public func startScan() async {
        scanTask?.cancel()
        pathUpdateTask?.cancel()
        progressPulseTask?.cancel()
        phase = .scanning
        progress = 0.04
        selectedResultIDs.removeAll()
        failedCleanupCount = 0
        results.removeAll()
        currentScannedPath = "Preparing \(moduleName)…"
        startPathUpdates()
        startProgressPulses()

        let scanStartedAt = ContinuousClock.now
        scanTask = Task {
            do {
                let result = try await scanner.scan()
                if Task.isCancelled { return }
                let elapsed = scanStartedAt.duration(to: .now)
                let remainingPresentation = minimumScanPresentationDuration - elapsed
                if remainingPresentation > .zero {
                    self.currentScannedPath = "Finalizing \(self.moduleName)…"
                    try? await Task.sleep(for: remainingPresentation)
                }
                if Task.isCancelled { return }
                self.results = self.sortedResults(from: result.results)
                self.progress = 1.0
                self.phase = .complete
                self.currentScannedPath = ""
            } catch {
                if Task.isCancelled { return }
                print("Scan failed for \(moduleName): \(error)")
                self.phase = .idle
                self.currentScannedPath = ""
            }
        }
        await scanTask?.value
        scanTask = nil
        pathUpdateTask?.cancel()
        pathUpdateTask = nil
        progressPulseTask?.cancel()
        progressPulseTask = nil
    }

    public func cancelScan() {
        scanTask?.cancel()
        pathUpdateTask?.cancel()
        progressPulseTask?.cancel()
        scanTask = nil
        pathUpdateTask = nil
        progressPulseTask = nil
        phase = .idle
        progress = 0
        selectedResultIDs.removeAll()
        isCleaningSelection = false
        currentScannedPath = ""
    }

    public var totalSize: Int64 {
        filteredResults.reduce(0) { $0 + $1.size }
    }

    public var selectedSize: Int64 {
        filteredResults.reduce(into: 0) { partialResult, result in
            guard selectedResultIDs.contains(result.id) else { return }
            partialResult += result.size
        }
    }

    public var isAllSelected: Bool {
        !filteredResults.isEmpty && filteredResults.allSatisfy { selectedResultIDs.contains($0.id) }
    }

    public func toggleSelectAll() {
        if isAllSelected {
            let filteredIDs = Set(filteredResults.map(\.id))
            selectedResultIDs.subtract(filteredIDs)
        } else {
            selectedResultIDs.formUnion(filteredResults.map(\.id))
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

        if !cleanupOutcome.removedIDs.isEmpty {
            UserDefaults.standard.set(Date(), forKey: "LastCleanedDate")
        }
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

    private func startPathUpdates() {
        let notificationName = scanPathUpdatedNotification
        let updateInterval = minimumPathUpdateInterval

        pathUpdateTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let stream = NotificationCenter.default.notifications(named: notificationName)
            let clock = ContinuousClock()
            var lastPathUpdate: ContinuousClock.Instant?
            var lastPublishedPath = ""

            for await notification in stream {
                guard !Task.isCancelled else { break }

                guard let path = notification.object as? String, path != lastPublishedPath else {
                    continue
                }

                let now = clock.now
                if let lastPathUpdate, lastPathUpdate.duration(to: now) < updateInterval {
                    continue
                }

                lastPathUpdate = now
                lastPublishedPath = path

                await self.updateCurrentScannedPath(path)
            }
        }
    }

    private func startProgressPulses() {
        progressPulseTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(90))
                guard !Task.isCancelled else { break }
                guard self.phase == .scanning else { continue }
                self.progress = min(self.progress + 0.022, 0.94)
            }
        }
    }

    private func updateCurrentScannedPath(_ path: String) {
        currentScannedPath = path
    }
}
