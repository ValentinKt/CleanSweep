import Foundation

public actor StartupManagerScanner: ModuleScanner {
    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDirs = [
            URL(fileURLWithPath: "/Library/LaunchAgents"),
            URL(fileURLWithPath: "/Library/LaunchDaemons"),
            homeDir.appendingPathComponent("Library/LaunchAgents")
        ]

        var results: [ScanResult] = []

        for dir in targetDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                do {
                    let contents = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .creationDateKey], options: [.skipsHiddenFiles])
                    for url in contents {
                        if url.pathExtension == "plist" {
                            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                            let size = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
                            let lastModified = attributes?[.modificationDate] as? Date
                            let creationDate = attributes?[.creationDate] as? Date
                            let appName = url.deletingPathExtension().lastPathComponent

                            let result = ScanResult(
                                url: url,
                                size: size,
                                category: .startupItem,
                                lastModified: lastModified,
                                creationDate: creationDate,
                                appName: appName
                            )
                            results.append(result)
                        }
                    }
                } catch {
                    // Ignore errors for unreadable directories
                }
            }
        }

        return ModuleResult(moduleName: "Startup Manager", results: results)
    }
}
