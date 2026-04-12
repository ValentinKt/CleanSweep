import Foundation

public actor SystemJunkScanner: ModuleScanner {
    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targets: [(URL, FileCategory)] = [
            (homeDir.appendingPathComponent("Library/Caches"), .userCache),
            (homeDir.appendingPathComponent("Library/Logs"), .systemLog)
        ]

        var allResults: [ScanResult] = []
        let categorizer = Categorizer()

        for (dir, category) in targets {
            guard !Task.isCancelled else { break }

            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }

            let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey]
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for child in contents {
                guard !Task.isCancelled else { break }

                let values = try? child.resourceValues(forKeys: Set(keys))
                if values?.isSymbolicLink == true { continue }

                Self.publishPathUpdate(for: child)

                if let result = await aggregateResult(
                    at: child,
                    category: category,
                    fileManager: fileManager,
                    categorizer: categorizer
                ) {
                    allResults.append(result)
                }
            }
        }

        return ModuleResult(moduleName: "System Junk", results: allResults)
    }

    private func aggregateResult(
        at url: URL,
        category: FileCategory,
        fileManager: FileManager,
        categorizer: Categorizer
    ) async -> ScanResult? {
        guard let resourceValues = try? url.resourceValues(
            forKeys: [.contentModificationDateKey, .creationDateKey, .isSymbolicLinkKey]
        ) else { return nil }

        if resourceValues.isSymbolicLink == true { return nil }

        let size = await allocatedSize(of: url, fileManager: fileManager)
        guard size > 0 else { return nil }

        let baseResult = ScanResult(
            url: url,
            size: size,
            category: category,
            lastModified: resourceValues.contentModificationDate,
            creationDate: resourceValues.creationDate,
            appName: nil
        )

        return ScanResult(
            url: baseResult.url,
            size: baseResult.size,
            category: baseResult.category,
            lastModified: baseResult.lastModified,
            creationDate: baseResult.creationDate,
            appName: baseResult.appName,
            severity: categorizer.severity(for: baseResult),
            isSafeToDelete: categorizer.isSafeToDelete(for: baseResult)
        )
    }

    private func allocatedSize(of url: URL, fileManager: FileManager) async -> Int64 {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .totalFileAllocatedSizeKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else { return 0 }

        if values.isSymbolicLink == true { return 0 }

        if values.isDirectory != true {
            let size = values.totalFileAllocatedSize ?? values.fileSize ?? 0
            return Int64(size)
        }

        return await Task.detached(priority: .utility) {
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles]
            ) else { return 0 }

            var totalSize: Int64 = 0
            var itemCount = 0

            while let child = enumerator.nextObject() as? URL {
                guard !Task.isCancelled else { break }

                do {
                    let childValues = try child.resourceValues(forKeys: keys)
                    if childValues.isSymbolicLink == true || childValues.isDirectory == true {
                        continue
                    }

                    let childSize = childValues.totalFileAllocatedSize ?? childValues.fileSize ?? 0
                    totalSize += Int64(childSize)
                    itemCount += 1

                    if itemCount.isMultiple(of: 1000) {
                        Self.publishPathUpdate(for: child)
                        await Task.yield()
                    }
                } catch {
                    continue
                }
            }

            return totalSize
        }.value
    }

    private nonisolated static func publishPathUpdate(for url: URL) {
        NotificationCenter.default.post(
            name: NSNotification.Name("ScanPathUpdated"),
            object: url.path
        )
    }
}
