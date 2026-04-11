import SwiftUI
import Observation
import ScanEngine

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
    var reviewSeedDestination: SidebarItem?
    var reviewSeedID = UUID()

    private let scanPathUpdatedNotification = NSNotification.Name("ScanPathUpdated")
    private let minimumPathUpdateInterval = Duration.milliseconds(150)
    private let engine = SmartScanEngine()
    private var scanTask: Task<Void, Never>?
    private var pathUpdateTask: Task<Void, Never>?
    private var progressAnimationTask: Task<Void, Never>?
    private var targetProgress: Double = 0

    public init() {}

    func prepareReview(for destination: SidebarItem) {
        reviewSeedDestination = destination
        reviewSeedID = UUID()
    }

    func clearReviewSeed() {
        reviewSeedDestination = nil
    }

    public func startScan() async {
        guard phase != .scanning else { return }

        scanTask?.cancel()
        pathUpdateTask?.cancel()
        progressAnimationTask?.cancel()
        prepareForScan()
        startPathUpdates()
        startProgressAnimation()

        scanTask = Task { [weak self] in
            guard let self else { return }

            do {
                let scanSummary = try await engine.scanAllModules { [weak self] progress, moduleName in
                    guard let self, !Task.isCancelled else { return }
                    self.targetProgress = progress
                    self.activeModuleName = moduleName
                }

                if Task.isCancelled { return }

                self.finishScan(with: scanSummary)
            } catch {
                if Task.isCancelled { return }
                print("Scan failed: \(error)")
                self.phase = .idle
            }
        }

        await scanTask?.value
        scanTask = nil
        pathUpdateTask?.cancel()
        pathUpdateTask = nil
        progressAnimationTask?.cancel()
        progressAnimationTask = nil
    }

    public func cancelScan() {
        scanTask?.cancel()
        pathUpdateTask?.cancel()
        progressAnimationTask?.cancel()
        scanTask = nil
        pathUpdateTask = nil
        progressAnimationTask = nil
        phase = .idle
        progress = 0
        targetProgress = 0
        activeModuleName = "Cancelled"
        currentScannedPath = ""
    }

    private func prepareForScan() {
        phase = .scanning
        progress = 0
        targetProgress = 0
        results = []
        summary = nil
        reviewSeedDestination = nil
        activeModuleName = "Preparing..."
        currentScannedPath = ""
    }

    private func startProgressAnimation() {
        progressAnimationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                guard let self else { break }

                // Gradually approach the target progress, and smoothly increment slightly even if waiting
                if self.progress < self.targetProgress {
                    self.progress += (self.targetProgress - self.progress) * 0.05 + 0.001
                    if self.progress > self.targetProgress {
                        self.progress = self.targetProgress
                    }
                } else if self.progress < 0.99 {
                    // Slowly increment while waiting for the next module to complete
                    self.progress += 0.0002
                }
            }
        }
    }

    private func finishScan(with scanSummary: ScanSummary) {
        summary = scanSummary
        results = scanSummary.allResults
        progress = 1.0
        phase = .complete
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

    private func updateCurrentScannedPath(_ path: String) {
        currentScannedPath = path
    }
}
