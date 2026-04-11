import Foundation

public actor ScanActor {
    private let categorizer = Categorizer()
    private static let minimumPathUpdateInterval = Duration.milliseconds(150)
    private static let pathUpdateStride = 128

    public init() {}

    public func scanStream(at root: URL, onPath: (@Sendable (URL) -> Void)? = nil) -> AsyncStream<ScanResult> {
        AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                let keys: [URLResourceKey] = [
                    .fileSizeKey,
                    .totalFileAllocatedSizeKey,
                    .contentModificationDateKey,
                    .contentAccessDateKey,
                    .isDirectoryKey,
                    .isSymbolicLinkKey,
                    .isPackageKey
                ]

                let enumerator = FileManager.default.enumerator(
                    at: root,
                    includingPropertiesForKeys: keys,
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                )

                let localCategorizer = Categorizer()
                let clock = ContinuousClock()

                var fileCount = 0
                var lastPathUpdate: ContinuousClock.Instant?

                while let url = enumerator?.nextObject() as? URL {
                    guard !Task.isCancelled else { break }

                    fileCount += 1

                    // Throttling: yield every 256 files to keep CPU usage low
                    if fileCount % 256 == 0 {
                        await Task.yield()
                    }

                    if Self.shouldPublishPathUpdate(
                        fileCount: fileCount,
                        clock: clock,
                        lastPathUpdate: lastPathUpdate
                    ) {
                        lastPathUpdate = clock.now
                        Self.publishPathUpdate(for: url)
                        onPath?(url)
                    }

                    do {
                        let values = try url.resourceValues(forKeys: Set(keys))

                        if let isDir = values.isDirectory, isDir { continue }
                        if let isSym = values.isSymbolicLink, isSym { continue }

                        let size = values.totalFileAllocatedSize ?? values.fileSize ?? 0
                        guard size > 0 else { continue }

                        if let category = localCategorizer.category(for: url, attributes: values) {
                            var result = ScanResult(
                                url: url,
                                size: Int64(size),
                                category: category,
                                lastModified: values.contentModificationDate,
                                creationDate: nil,
                                appName: nil
                            )
                            result = ScanResult(
                                url: result.url,
                                size: result.size,
                                category: result.category,
                                lastModified: result.lastModified,
                                creationDate: result.creationDate,
                                appName: result.appName,
                                severity: localCategorizer.severity(for: result)
                            )
                            continuation.yield(result)
                        }
                    } catch {
                        continue
                    }
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func scanAllStream(at root: URL, onPath: (@Sendable (URL) -> Void)? = nil) -> AsyncStream<ScanResult> {
        AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                let keys: [URLResourceKey] = [
                    .fileSizeKey,
                    .totalFileAllocatedSizeKey,
                    .contentModificationDateKey,
                    .contentAccessDateKey,
                    .isDirectoryKey,
                    .isSymbolicLinkKey,
                    .isPackageKey
                ]

                let enumerator = FileManager.default.enumerator(
                    at: root,
                    includingPropertiesForKeys: keys,
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                )

                let localCategorizer = Categorizer()
                let clock = ContinuousClock()
                var fileCount = 0
                var lastPathUpdate: ContinuousClock.Instant?

                while let url = enumerator?.nextObject() as? URL {
                    guard !Task.isCancelled else { break }

                    fileCount += 1

                    // Throttling: yield every 256 files to keep CPU usage low
                    if fileCount % 256 == 0 {
                        await Task.yield()
                    }

                    if Self.shouldPublishPathUpdate(
                        fileCount: fileCount,
                        clock: clock,
                        lastPathUpdate: lastPathUpdate
                    ) {
                        lastPathUpdate = clock.now
                        Self.publishPathUpdate(for: url)
                        onPath?(url)
                    }

                    do {
                        let values = try url.resourceValues(forKeys: Set(keys))

                        if let isDir = values.isDirectory, isDir { continue }
                        if let isSym = values.isSymbolicLink, isSym { continue }

                        let size = values.totalFileAllocatedSize ?? values.fileSize ?? 0
                        guard size > 0 else { continue }

                        let result = ScanResult(
                            url: url,
                            size: Int64(size),
                            category: .unknown,
                            lastModified: values.contentModificationDate,
                            creationDate: nil,
                            appName: nil,
                            severity: localCategorizer.severity(for: ScanResult(
                                url: url,
                                size: Int64(size),
                                category: .unknown,
                                lastModified: values.contentModificationDate,
                                creationDate: nil,
                                appName: nil
                            ))
                        )
                        continuation.yield(result)
                    } catch {
                        continue
                    }
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private nonisolated static func shouldPublishPathUpdate(
        fileCount: Int,
        clock: ContinuousClock,
        lastPathUpdate: ContinuousClock.Instant?
    ) -> Bool {
        guard fileCount == 1 || fileCount % pathUpdateStride == 0 else {
            return false
        }

        let now = clock.now
        guard let lastPathUpdate else {
            return true
        }

        return lastPathUpdate.duration(to: now) >= minimumPathUpdateInterval
    }

    private nonisolated static func publishPathUpdate(for url: URL) {
        NotificationCenter.default.post(
            name: NSNotification.Name("ScanPathUpdated"),
            object: url.path
        )
    }
}
