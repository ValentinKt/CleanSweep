import SwiftUI
import Combine

@MainActor
@Observable
class HealthDashboardViewModel {
    var freeSpace: String = "Calculating..."
    var memoryStatus: String = "Calculating..."
    var lastCleaned: String = "Never"

    init() {
        updateStats()
    }

    func updateStats() {
        Task {
            freeSpace = getFreeDiskSpace()
            memoryStatus = "Normal" // In a real app, query Mach API
            lastCleaned = "Just now" // Fetch from UserDefaults in a real app
        }
    }

    private func getFreeDiskSpace() -> String {
        let fileURL = URL(fileURLWithPath: "/")
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useGB, .useTB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: capacity)
            }
        } catch {
            print("Error retrieving disk capacity: \(error)")
        }
        return "Unknown"
    }
}
