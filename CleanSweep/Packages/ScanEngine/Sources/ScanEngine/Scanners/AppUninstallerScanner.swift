import Foundation

public actor AppUninstallerScanner: ModuleScanner {
    private let scanActor = ScanActor()

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
                // Read contents of Applications directory
                do {
                    let contents = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .creationDateKey], options: [.skipsHiddenFiles])
                    for url in contents {
                        if url.pathExtension == "app" {
                            let size = await calculateSize(of: url)
                            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                            let lastModified = attributes?[.modificationDate] as? Date
                            let creationDate = attributes?[.creationDate] as? Date
                            let appName = url.deletingPathExtension().lastPathComponent

                            let result = ScanResult(
                                url: url,
                                size: size,
                                category: .application,
                                lastModified: lastModified,
                                creationDate: creationDate,
                                appName: appName
                            )
                            apps.append(result)
                        }
                    }
                } catch {
                    // Ignore errors for unreadable directories
                }
            }
        }

        return ModuleResult(moduleName: "App Uninstaller", results: apps)
    }

    private func calculateSize(of url: URL) async -> Int64 {
        return await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            var size: Int64 = 0
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]) {
                var fileCount = 0
                for case let fileURL as URL in enumerator {
                    guard !Task.isCancelled else { break }
                    
                    fileCount += 1
                    if fileCount % 1000 == 0 {
                        await Task.yield()
                        NotificationCenter.default.post(name: NSNotification.Name("ScanPathUpdated"), object: fileURL.path)
                    }

                    if let resources = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]) {
                        size += Int64(resources.totalFileAllocatedSize ?? resources.fileSize ?? 0)
                    }
                }
            }
            return size
        }.value
    }
}
