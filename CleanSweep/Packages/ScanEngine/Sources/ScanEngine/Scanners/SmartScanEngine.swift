import Foundation

public actor SmartScanEngine {
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

        var summary = ScanSummary()
        let totalModules = scanJobs.count

        for (index, job) in scanJobs.enumerated() {
            if let onProgress {
                let progress = Double(index) / Double(totalModules)
                await onProgress(progress, job.0)
            }
            
            let result = try await job.1()
            summary.merge(result)
        }

        if let onProgress {
            await onProgress(1.0, "Complete")
        }

        return summary
    }
}
