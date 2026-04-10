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
                            let size = calculateSize(of: url)
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

    private func calculateSize(of url: URL) -> Int64 {
        let fileManager = FileManager.default
        var size: Int64 = 0
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let resources = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resources.fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        return size
    }
}
