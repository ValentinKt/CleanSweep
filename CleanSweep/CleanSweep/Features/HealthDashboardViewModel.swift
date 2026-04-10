import SwiftUI
import Combine

@MainActor
@Observable
class HealthDashboardViewModel {
    var freeSpace: String = "Calculating..."
    var memoryStatus: String = "Calculating..."
    var lastCleaned: String = "Never"

    private var currentTask: Task<Void, Never>?

    init() {
        updateStats()
    }

    func updateStats() {
        currentTask?.cancel()
        currentTask = Task {
            let diskSpace = await getFreeDiskSpace()
            if Task.isCancelled { return }
            freeSpace = diskSpace
            memoryStatus = "Normal" // In a real app, query Mach API
            lastCleaned = "Just now" // Fetch from UserDefaults in a real app
        }
    }

    private func getFreeDiskSpace() async -> String {
        return await Task.detached(priority: .userInitiated) {
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
        }.value
    }
}
