import Foundation

public actor DevelopmentJunkScanner: ModuleScanner {
    private static let scanNotificationName = NSNotification.Name("ScanPathUpdated")
    private static let sizingYieldStride = 256

    public init() {}

    public func scan() async throws -> ModuleResult {
        try await scanSnapshot(fileManager: .default, homeDirectory: nil)
    }

    public func scanSnapshot(
        fileManager: FileManager = .default,
        homeDirectory: URL? = nil
    ) async throws -> ModuleResult {
        let categorizer = Categorizer()
        let targets = Self.scanTargets(fileManager: fileManager, homeDirectory: homeDirectory)
        var allResults: [ScanResult] = []

        for target in targets {
            guard !Task.isCancelled else { break }
            Self.publishPathUpdate(target.url)
            let targetResults = try await scanTarget(
                target,
                fileManager: fileManager,
                categorizer: categorizer
            )
            allResults.append(contentsOf: targetResults)
            await Task.yield()
        }

        return ModuleResult(moduleName: "Developer Junk", results: allResults)
    }

    public static func targetDirectories(
        fileManager: FileManager = .default,
        homeDirectory: URL? = nil
    ) -> [URL] {
        scanTargets(fileManager: fileManager, homeDirectory: homeDirectory).map(\.url)
    }

    static func scanTargets(
        fileManager: FileManager = .default,
        homeDirectory: URL? = nil
    ) -> [ScanTarget] {
        let homeDir = homeDirectory ?? fileManager.homeDirectoryForCurrentUser
        var candidates = baseTargets(homeDir: homeDir)
        candidates.append(contentsOf: simulatorDeviceTargets(homeDir: homeDir, fileManager: fileManager))

        var seenPaths = Set<String>()

        return candidates
            .filter { isDirectory($0.url, using: fileManager) }
            .filter { seenPaths.insert($0.url.standardizedFileURL.path).inserted }
            .sorted { lhs, rhs in
                lhs.url.path.localizedStandardCompare(rhs.url.path) == .orderedAscending
            }
    }

    private static func baseTargets(homeDir: URL) -> [ScanTarget] {
        [
            ScanTarget(
                url: homeDir.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
                category: .xcodeDerivedData,
                strategy: .immediateChildren
            ),
            ScanTarget(
                url: homeDir.appendingPathComponent("Library/Developer/Xcode/Archives"),
                category: .xcodeDerivedData,
                strategy: .immediateChildren
            ),
            ScanTarget(
                url: homeDir.appendingPathComponent("Library/Developer/CoreSimulator/Caches"),
                category: .xcodeSimulator,
                strategy: .immediateChildren
            ),
            ScanTarget(
                url: homeDir.appendingPathComponent("Library/Caches/org.swift.swiftpm"),
                category: .spmCache,
                strategy: .immediateChildren
            ),
            ScanTarget(
                url: homeDir.appendingPathComponent(".cache/org.swift.swiftpm"),
                category: .spmCache,
                strategy: .immediateChildren
            ),
            ScanTarget(
                url: homeDir.appendingPathComponent("Library/Caches/CocoaPods"),
                category: .spmCache,
                strategy: .immediateChildren
            ),
            ScanTarget(
                url: homeDir.appendingPathComponent("Library/Caches/org.carthage.CarthageKit"),
                category: .spmCache,
                strategy: .immediateChildren
            )
        ]
    }

    private static func simulatorDeviceTargets(homeDir: URL, fileManager: FileManager) -> [ScanTarget] {
        let simulatorDevicesRoot = homeDir.appendingPathComponent("Library/Developer/CoreSimulator/Devices")
        guard let deviceDirectories = try? fileManager.contentsOfDirectory(
            at: simulatorDevicesRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return deviceDirectories
            .filter { isDirectory($0, using: fileManager) }
            .flatMap { deviceDirectory in
                [
                    ScanTarget(
                        url: deviceDirectory.appendingPathComponent("data/Library/Caches"),
                        category: .xcodeSimulator,
                        strategy: .directoryOnly
                    ),
                    ScanTarget(
                        url: deviceDirectory.appendingPathComponent("data/Library/Logs"),
                        category: .xcodeSimulator,
                        strategy: .directoryOnly
                    ),
                    ScanTarget(
                        url: deviceDirectory.appendingPathComponent("data/tmp"),
                        category: .xcodeSimulator,
                        strategy: .directoryOnly
                    )
                ]
            }
    }

    private func scanTarget(
        _ target: ScanTarget,
        fileManager: FileManager,
        categorizer: Categorizer
    ) async throws -> [ScanResult] {
        switch target.strategy {
        case .directoryOnly:
            if let result = try await aggregateResult(
                at: target.url,
                category: target.category,
                fileManager: fileManager,
                categorizer: categorizer
            ) {
                return [result]
            }
            return []
        case .immediateChildren:
            let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey]
            let contents = try fileManager.contentsOfDirectory(
                at: target.url,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            )

            var results: [ScanResult] = []

            for child in contents.sorted(by: Self.compareURLs(_:_:)) {
                guard !Task.isCancelled else { break }
                let values = try? child.resourceValues(forKeys: Set(keys))
                if values?.isSymbolicLink == true {
                    continue
                }

                Self.publishPathUpdate(child)

                if let result = try await aggregateResult(
                    at: child,
                    category: target.category,
                    fileManager: fileManager,
                    categorizer: categorizer
                ) {
                    results.append(result)
                }
            }

            if results.isEmpty,
               let result = try await aggregateResult(
                   at: target.url,
                   category: target.category,
                   fileManager: fileManager,
                   categorizer: categorizer
               ) {
                results.append(result)
            }

            return results
        }
    }

    private func aggregateResult(
        at url: URL,
        category: FileCategory,
        fileManager: FileManager,
        categorizer: Categorizer
    ) async throws -> ScanResult? {
        let resourceValues = try url.resourceValues(
            forKeys: [.contentModificationDateKey, .creationDateKey, .isSymbolicLinkKey]
        )
        if resourceValues.isSymbolicLink == true {
            return nil
        }

        let size = try await allocatedSize(of: url, fileManager: fileManager)
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

    private func allocatedSize(of url: URL, fileManager: FileManager) async throws -> Int64 {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .totalFileAllocatedSizeKey
        ]
        let values = try url.resourceValues(forKeys: keys)

        if values.isSymbolicLink == true {
            return 0
        }

        if values.isDirectory != true {
            let size = values.totalFileAllocatedSize ?? values.fileSize ?? 0
            return Int64(size)
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var totalSize: Int64 = 0
        var itemCount = 0

        while let child = enumerator.nextObject() as? URL {
            guard !Task.isCancelled else { break }

            let childValues = try? child.resourceValues(forKeys: keys)
            if childValues?.isSymbolicLink == true || childValues?.isDirectory == true {
                continue
            }

            let childSize = childValues?.totalFileAllocatedSize ?? childValues?.fileSize ?? 0
            totalSize += Int64(childSize)
            itemCount += 1

            if itemCount.isMultiple(of: Self.sizingYieldStride) {
                try? await Task.sleep(for: .milliseconds(2))
                await Task.yield()
            }
        }

        return totalSize
    }

}

extension DevelopmentJunkScanner {
    struct ScanTarget: Sendable {
        let url: URL
        let category: FileCategory
        let strategy: ScanStrategy
    }

    enum ScanStrategy: Sendable {
        case directoryOnly
        case immediateChildren
    }
}

extension DevelopmentJunkScanner {
    nonisolated private static func publishPathUpdate(_ url: URL) {
        NotificationCenter.default.post(name: scanNotificationName, object: url.path)
    }

    nonisolated private static func compareURLs(_ lhs: URL, _ rhs: URL) -> Bool {
        lhs.path.localizedStandardCompare(rhs.path) == .orderedAscending
    }

    nonisolated private static func isDirectory(_ url: URL, using fileManager: FileManager) -> Bool {
        var isDirectoryFlag: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectoryFlag) && isDirectoryFlag.boolValue
    }
}
