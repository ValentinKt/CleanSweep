import Foundation

public actor ScanActor {
    private let categorizer = Categorizer()

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
                    if fileCount % 4096 == 0 {
                        await Task.yield()
                        let now = clock.now

                        if let lastPathUpdate, lastPathUpdate.duration(to: now) < .milliseconds(150) {
                            continue
                        }

                        lastPathUpdate = now
                        NotificationCenter.default.post(name: NSNotification.Name("ScanPathUpdated"), object: url.path)
                        onPath?(url)
                    }

                    do {
                        let values = try url.resourceValues(forKeys: Set(keys))

                        if let isDir = values.isDirectory, isDir { continue }
                        if let isSym = values.isSymbolicLink, isSym { continue }

                        let size = values.totalFileAllocatedSize ?? values.fileSize ?? 0
                        guard size > 0 else { continue }

                        if let category = await localCategorizer.category(for: url, attributes: values) {
                            let result = ScanResult(
                                url: url,
                                size: Int64(size),
                                category: category,
                                lastModified: values.contentModificationDate,
                                creationDate: nil,
                                appName: nil
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

                let clock = ContinuousClock()
                var fileCount = 0
                var lastPathUpdate: ContinuousClock.Instant?

                while let url = enumerator?.nextObject() as? URL {
                    guard !Task.isCancelled else { break }

                    fileCount += 1
                    if fileCount % 4096 == 0 {
                        await Task.yield()
                        let now = clock.now

                        if let lastPathUpdate, lastPathUpdate.duration(to: now) < .milliseconds(150) {
                            continue
                        }

                        lastPathUpdate = now
                        NotificationCenter.default.post(name: NSNotification.Name("ScanPathUpdated"), object: url.path)
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
                            appName: nil
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
}
