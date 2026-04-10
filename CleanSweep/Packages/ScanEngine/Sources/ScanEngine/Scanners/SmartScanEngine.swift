import Foundation

public actor SmartScanEngine {
    private let maxConcurrentModules = 2

    public init() {}

    public func scanAllModules(onProgress: (@MainActor @Sendable (Double, String) -> Void)? = nil) async throws -> ScanSummary {
        let scanJobs: [@Sendable () async throws -> ModuleResult] = [
            { try await TrashScanner().scan() },
            { try await MailAttachmentScanner().scan() },
            { try await PrivacyScanner().scan() },
            { try await StartupManagerScanner().scan() },
            { try await FontManagerScanner().scan() },
            { try await NetworkCacheScanner().scan() },
            { try await ScreenshotScanner().scan() },
            { try await SystemJunkScanner().scan() },
            { try await DevelopmentJunkScanner().scan() },
            { try await LargeFilesScanner().scan() },
            { try await AppUninstallerScanner().scan() },
            { try await DuplicateFinderScanner().scan() }
        ]

        return try await withThrowingTaskGroup(of: ModuleResult.self) { group in
            var summary = ScanSummary()
            let totalModules = scanJobs.count
            var completedModules = 0
            var nextJobIndex = 0

            func enqueueNextJob() {
                guard nextJobIndex < scanJobs.count else { return }
                let job = scanJobs[nextJobIndex]
                nextJobIndex += 1
                group.addTask {
                    try await job()
                }
            }

            for _ in 0..<min(maxConcurrentModules, scanJobs.count) {
                enqueueNextJob()
            }

            while let result = try await group.next() {
                summary.merge(result)
                completedModules += 1
                let progress = Double(completedModules) / Double(totalModules)

                if let onProgress {
                    await onProgress(progress, result.moduleName)
                }

                enqueueNextJob()
            }

            return summary
        }
    }
}
