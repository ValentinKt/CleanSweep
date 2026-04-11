import Foundation

public actor SmartScanEngine {
    private let maxConcurrentModules = 1

    public init() {}

    public func scanAllModules(onProgress: (@MainActor @Sendable (Double, String) -> Void)? = nil) async throws -> ScanSummary {
        let scanJobs: [(String, @Sendable () async throws -> ModuleResult)] = [
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

        return try await withThrowingTaskGroup(of: ModuleResult.self) { group in
            var summary = ScanSummary()
            let totalModules = scanJobs.count
            var completedModules = 0
            var nextJobIndex = 0

            func enqueueNextJob() async {
                guard nextJobIndex < scanJobs.count else { return }
                let job = scanJobs[nextJobIndex]
                nextJobIndex += 1

                if let onProgress {
                    let progress = Double(completedModules) / Double(totalModules)
                    await onProgress(progress, job.0)
                }

                group.addTask {
                    try await job.1()
                }
            }

            for _ in 0..<min(maxConcurrentModules, scanJobs.count) {
                await enqueueNextJob()
            }

            while let result = try await group.next() {
                summary.merge(result)
                completedModules += 1
                await enqueueNextJob()
            }

            if let onProgress {
                await onProgress(1.0, "Complete")
            }

            return summary
        }
    }
}
