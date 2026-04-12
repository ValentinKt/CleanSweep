import Foundation

public actor AppUninstallerScanner: ModuleScanner {
    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDirs = [
            URL(fileURLWithPath: "/Applications"),
            homeDir.appendingPathComponent("Applications")
        ]

        var apps: [ScanResult] = []

        for dir in targetDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                do {
                    let contents = try fileManager.contentsOfDirectory(
                        at: dir,
                        includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .creationDateKey],
                        options: [.skipsHiddenFiles]
                    )

                    let categorizer = Categorizer()
                    for url in contents where url.pathExtension == "app" {
                        let size = await calculateSize(of: url)
                        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                        let lastModified = attributes?[.modificationDate] as? Date
                        let creationDate = attributes?[.creationDate] as? Date
                        let appName = url.deletingPathExtension().lastPathComponent

                        let baseResult = ScanResult(
                            url: url,
                            size: size,
                            category: .application,
                            lastModified: lastModified,
                            creationDate: creationDate,
                            appName: appName
                        )

                        let result = ScanResult(
                            url: baseResult.url,
                            size: baseResult.size,
                            category: baseResult.category,
                            lastModified: baseResult.lastModified,
                            creationDate: baseResult.creationDate,
                            appName: baseResult.appName,
                            severity: categorizer.severity(for: baseResult),
                            isSafeToDelete: categorizer.isSafeToDelete(for: baseResult)
                        )
                        apps.append(result)
                    }
                } catch {
                }
            }
        }

        return ModuleResult(moduleName: "App Uninstaller", results: apps)
    }

    private func calculateSize(of url: URL) async -> Int64 {
        return await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            let clock = ContinuousClock()
            var size: Int64 = 0
            var lastPathUpdate: ContinuousClock.Instant?
            if let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]
            ) {
                var fileCount = 0
                while let fileURL = enumerator.nextObject() as? URL {
                    guard !Task.isCancelled else { break }

                    fileCount += 1

                    // Throttling: yield every 256 files to keep CPU usage low
                    if fileCount % 256 == 0 {
                        await Task.yield()
                    }

                    if fileCount % 4096 == 0 {
                        await Task.yield()
                        let now = clock.now

                        if let lastPathUpdate, lastPathUpdate.duration(to: now) < .milliseconds(150) {
                            continue
                        }

                        lastPathUpdate = now
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ScanPathUpdated"),
                            object: fileURL.path
                        )
                    }

                    if let resources = try? fileURL.resourceValues(
                        forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]
                    ) {
                        size += Int64(resources.totalFileAllocatedSize ?? resources.fileSize ?? 0)
                    }
                }
            }
            return size
        }.value
    }
}
