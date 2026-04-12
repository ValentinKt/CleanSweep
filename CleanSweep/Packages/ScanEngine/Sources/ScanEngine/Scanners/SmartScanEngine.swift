import Foundation

public actor SmartScanEngine {
    public init() {}

    private var scanJobs: [(String, @Sendable () async throws -> ModuleResult)] {
        [
            ("Trash", { try await TrashScanner().scan() }),
            ("Mail Attachments", { try await MailAttachmentScanner().scan() }),
            ("Privacy", { try await PrivacyScanner().scan() }),
            ("Startup Items", { try await StartupManagerScanner().scan() }),
            ("Fonts", { try await FontManagerScanner().scan() }),
            ("Network Cache", { try await NetworkCacheScanner().scan() }),
            ("Screenshots", { try await ScreenshotScanner().scan() }),
            ("System Junk", { try await SystemJunkScanner().scan() }),
            ("Developer Junk", { try await DevelopmentJunkScanner().scan() }),
            ("Large & Old Files", { try await LargeFilesScanner().scan() }),
            ("App Uninstaller", { try await AppUninstallerScanner().scan() }),
            ("Leftovers", { try await LeftoversScanner().scan() }),
            ("Duplicates", { try await DuplicateFinderScanner().scan() })
        ]
    }

    public func scanAllModules(
        onProgress: (@MainActor @Sendable (Double, String) -> Void)? = nil
    ) async throws -> ScanSummary {
        let jobs = scanJobs
        var summary = ScanSummary()
        let totalModules = jobs.count
        let cap = 4

        try await withThrowingTaskGroup(of: (Int, ModuleResult).self) { group in
            var active = 0
            var completedCount = 0

            for (index, job) in jobs.enumerated() {
                if active >= cap, let (_, result) = try await group.next() {
                    completedCount += 1
                    summary.merge(result)
                    if let onProgress {
                        let progress = Double(completedCount) / Double(totalModules)
                        await onProgress(progress, result.moduleName)
                    }
                    active -= 1
                }

                group.addTask(priority: .utility) {
                    try Task.checkCancellation()
                    let result = try await job.1()
                    return (index, result)
                }
                active += 1
            }

            for try await (_, result) in group {
                completedCount += 1
                summary.merge(result)
                if let onProgress {
                    let progress = Double(completedCount) / Double(totalModules)
                    await onProgress(progress, result.moduleName)
                }
            }
        }

        if let onProgress {
            await onProgress(1.0, "Complete")
        }

        return summary
    }
}
