import SwiftUI
import Observation
import ScanEngine // Will need to link the package in Xcode

public enum ScanPhase: Sendable {
    case idle
    case scanning
    case complete
}

@MainActor
@Observable
public final class SmartScanViewModel {
    public var results: [ScanResult] = []
    public var progress: Double = 0
    public var phase: ScanPhase = .idle
    public var summary: ScanSummary?
    public var activeModuleName: String = ""

    public var currentScannedPath: String = ""

    private let engine = SmartScanEngine()
    private var scanTask: Task<Void, Never>?
    private var pathUpdateTask: Task<Void, Never>?

    public init() {}

    public func startScan() async {
        scanTask?.cancel()
        pathUpdateTask?.cancel()
        
        phase = .scanning
        activeModuleName = "Preparing..."
        currentScannedPath = ""

        pathUpdateTask = Task {
            let stream = NotificationCenter.default.notifications(named: NSNotification.Name("ScanPathUpdated"))
            for await notification in stream {
                guard !Task.isCancelled else { break }
                if let path = notification.object as? String {
                    self.currentScannedPath = path
                }
            }
        }

        scanTask = Task {
            do {
                let scanSummary = try await engine.scanAllModules { [weak self] progress, moduleName in
                    Task { @MainActor in
                        guard let self = self, !Task.isCancelled else { return }
                        self.progress = progress
                        self.activeModuleName = moduleName
                    }
                }
                if Task.isCancelled { return }
                self.summary = scanSummary
                self.results = scanSummary.allResults
                self.progress = 1.0
                self.phase = .complete
            } catch {
                if Task.isCancelled { return }
                print("Scan failed: \(error)")
                self.phase = .idle
            }
        }
        await scanTask?.value
        pathUpdateTask?.cancel()
    }
    
    public func cancelScan() {
        scanTask?.cancel()
        pathUpdateTask?.cancel()
        phase = .idle
        progress = 0
        activeModuleName = "Cancelled"
        currentScannedPath = ""
    }
}
