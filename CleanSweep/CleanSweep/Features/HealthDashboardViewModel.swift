import SwiftUI
import Combine
import Darwin
import IOKit.ps

@MainActor
@Observable
class HealthDashboardViewModel {
    var freeSpace: String = "Calculating..."
    var memoryStatus: String = "Calculating..."
    var batteryStatus: String = "Calculating..."
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
            
            memoryStatus = getMemoryStatus()
            batteryStatus = getBatteryStatus()
            
            if let lastCleanedDate = UserDefaults.standard.object(forKey: "LastCleanedDate") as? Date {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                lastCleaned = formatter.localizedString(for: lastCleanedDate, relativeTo: Date())
            } else {
                lastCleaned = "Never"
            }
        }
    }

    private func getMemoryStatus() -> String {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let active = Int64(stats.active_count) * Int64(vm_page_size)
            let wired = Int64(stats.wire_count) * Int64(vm_page_size)
            let compressed = Int64(stats.compressor_page_count) * Int64(vm_page_size)
            let used = active + wired + compressed
            
            let physicalMemory = ProcessInfo.processInfo.physicalMemory
            guard physicalMemory > 0 else { return "Unknown" }
            let percentage = Int((Double(used) / Double(physicalMemory)) * 100)
            return "\(percentage)% Used"
        }
        return "Unknown"
    }

    private func getBatteryStatus() -> String {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return "Desktop"
        }
        
        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else { continue }
            
            if let capacity = info[kIOPSCurrentCapacityKey] as? Int,
               let max = info[kIOPSMaxCapacityKey] as? Int, max > 0 {
                return "\(Int((Double(capacity) / Double(max)) * 100))%"
            } else if let capacity = info["Current Capacity"] as? Int,
                      let max = info["Max Capacity"] as? Int, max > 0 {
                return "\(Int((Double(capacity) / Double(max)) * 100))%"
            }
        }
        return "Desktop"
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
