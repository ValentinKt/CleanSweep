import SwiftUI
import Observation
import Foundation
import Darwin

public extension NSNotification.Name {
    static let appDidBecomeActive = NSNotification.Name("AppDidBecomeActive")
    static let appDidBecomeInactive = NSNotification.Name("AppDidBecomeInactive")
}

@Observable @MainActor
public final class AppModel {
    public static let shared = AppModel()

    public var isAppActive: Bool = true
    public var cpuUsage: Double = 0
    public var memoryUsage: Double = 0

    private var metricsTask: Task<Void, Never>?
    private var ghostModeTask: Task<Void, Never>?
    private let lowPriorityQueue = DispatchQueue(label: "com.cleansweep.lowpriority", qos: .background)

    private init() {
        startMetrics()
    }

    public func resume() {
        isAppActive = true
        startMetrics()
        // Signal background tasks to resume if they use a custom throttle
        NotificationCenter.default.post(name: .appDidBecomeActive, object: nil)
    }

    public func suspend() {
        isAppActive = false
        stopMetrics()
        // Signal background tasks to enter ghost mode
        NotificationCenter.default.post(name: .appDidBecomeInactive, object: nil)
    }

    private func startMetrics() {
        guard metricsTask == nil else { return }

        metricsTask = Task {
            while !Task.isCancelled {
                // Update basic metrics every 2 seconds when active
                updateMetrics()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private func stopMetrics() {
        metricsTask?.cancel()
        metricsTask = nil
    }

    private func updateMetrics() {
        // Basic resource monitoring
        var stats = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            memoryUsage = Double(stats.resident_size) / 1024 / 1024 // MB
        }
    }
}
