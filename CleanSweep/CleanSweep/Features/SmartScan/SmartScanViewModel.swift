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

    private let engine = SmartScanEngine()

    public init() {}

    public func startScan() async {
        phase = .scanning
        activeModuleName = "System Junk" // In a real app, stream this from engine

        do {
            let scanSummary = try await engine.scanAllModules()
            self.summary = scanSummary
            self.results = scanSummary.allResults
            self.progress = 1.0
            self.phase = .complete
        } catch {
            print("Scan failed: \(error)")
            self.phase = .idle
        }
    }
}
