import Foundation

public actor SmartScanEngine {
    public init() {}

    public func scanAllModules() async throws -> ScanSummary {
        try await withThrowingTaskGroup(of: ModuleResult.self) { group in
            group.addTask { try await SystemJunkScanner().scan() }
            group.addTask { try await LargeFilesScanner().scan() }
            group.addTask { try await DevelopmentJunkScanner().scan() }
            group.addTask { try await ScreenshotScanner().scan() }
            group.addTask { try await DuplicateFinderScanner().scan() }
            group.addTask { try await MailAttachmentScanner().scan() }
            group.addTask { try await TrashScanner().scan() }
            group.addTask { try await PrivacyScanner().scan() }
            group.addTask { try await AppUninstallerScanner().scan() }
            group.addTask { try await StartupManagerScanner().scan() }
            group.addTask { try await NetworkCacheScanner().scan() }
            group.addTask { try await FontManagerScanner().scan() }

            var summary = ScanSummary()
            for try await result in group {
                summary.merge(result)
            }
            return summary
        }
    }
}
