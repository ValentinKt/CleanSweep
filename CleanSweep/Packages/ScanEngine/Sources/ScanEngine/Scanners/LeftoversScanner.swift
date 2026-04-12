import Foundation
import AppKit

public actor LeftoversScanner: ModuleScanner {
    public init() {}

    public func scan() async throws -> ModuleResult {
        let (installedAppNames, installedBundleIDs) = getInstalledApps()
        let leftovers = await findLeftovers(
            installedAppNames: installedAppNames,
            installedBundleIDs: installedBundleIDs
        )

        return ModuleResult(moduleName: "Leftovers", results: leftovers)
    }

    private func getInstalledApps() -> (Set<String>, Set<String>) {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            homeDir.appendingPathComponent("Applications")
        ]

        var installedAppNames: Set<String> = []
        var installedBundleIDs: Set<String> = []

        for dir in targetDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                do {
                    let contents = try fileManager.contentsOfDirectory(
                        at: dir,
                        includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles]
                    )

                    for url in contents where url.pathExtension == "app" {
                        let appName = url.deletingPathExtension().lastPathComponent
                        installedAppNames.insert(appName.lowercased())

                        if let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                            installedBundleIDs.insert(bundleID.lowercased())
                        }
                    }
                } catch {
                }
            }
        }
        return (installedAppNames, installedBundleIDs)
    }

    private func findLeftovers(installedAppNames: Set<String>, installedBundleIDs: Set<String>) async -> [ScanResult] {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        var leftovers: [ScanResult] = []
        let leftoverDirs = [
            homeDir.appendingPathComponent("Library/Application Support"),
            homeDir.appendingPathComponent("Library/Caches"),
            homeDir.appendingPathComponent("Library/Containers"),
            homeDir.appendingPathComponent("Library/Preferences")
        ]

        for dir in leftoverDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                do {
                    let contents = try fileManager.contentsOfDirectory(
                        at: dir,
                        includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .creationDateKey],
                        options: [.skipsHiddenFiles]
                    )

                    for url in contents {
                        guard !Task.isCancelled else { break }

                        if let result = await processLeftoverURL(
                            url,
                            installedAppNames: installedAppNames,
                            installedBundleIDs: installedBundleIDs,
                            fileManager: fileManager
                        ) {
                            leftovers.append(result)
                        }
                    }
                } catch {
                }
            }
        }
        return leftovers
    }

    private func processLeftoverURL(
        _ url: URL,
        installedAppNames: Set<String>,
        installedBundleIDs: Set<String>,
        fileManager: FileManager
    ) async -> ScanResult? {
        let ignoredNames: Set<String> = [
            "apple", "com.apple", "crashreporter", "coreduet", "mobiledocuments",
            "cloudkit", "syncservices", "appstore", "sharedsync", "knowledge",
            "iclouddrive", "icloud"
        ]

        let name = url.lastPathComponent
        let lowerName = name.lowercased()

        if ignoredNames.contains(where: { lowerName.contains($0) }) { return nil }

        let isBundleID = lowerName.contains(".") && lowerName.components(separatedBy: ".").count >= 2
        var baseName = lowerName
        if url.pathExtension == "plist" {
            baseName = url.deletingPathExtension().lastPathComponent.lowercased()
        }

        var isLeftover = false
        if isBundleID {
            if !installedBundleIDs.contains(baseName) {
                isLeftover = true
            }
        } else {
            if !installedAppNames.contains(baseName) {
                isLeftover = true
            }
        }

        guard isLeftover else { return nil }

        let size = await calculateSize(of: url)
        guard size > 0 else { return nil }

        let categorizer = Categorizer()
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let lastModified = attributes?[.modificationDate] as? Date
        let creationDate = attributes?[.creationDate] as? Date

        let baseResult = ScanResult(
            url: url,
            size: size,
            category: .application,
            lastModified: lastModified,
            creationDate: creationDate,
            appName: name
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

    private func calculateSize(of url: URL) async -> Int64 {
        return await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            let clock = ContinuousClock()
            var size: Int64 = 0
            var lastPathUpdate: ContinuousClock.Instant?

            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue {
                if let resources = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]) {
                    return Int64(resources.totalFileAllocatedSize ?? resources.fileSize ?? 0)
                }
                return 0
            }

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
