import Foundation

public actor PrivacyScanner: ModuleScanner {
    private let scanActor = ScanActor()

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetPaths = [
            homeDir.appendingPathComponent("Library/Safari/History.db"),
            homeDir.appendingPathComponent("Library/Cookies/Cookies.binarycookies"),
            homeDir.appendingPathComponent("Library/Application Support/Google/Chrome/Default/History"),
            homeDir.appendingPathComponent("Library/Application Support/Firefox/Profiles"),
            homeDir.appendingPathComponent("Library/Application Support/com.apple.sharedfilelist")
        ]

        var allResults: [ScanResult] = []

        for path in targetPaths {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    for await result in await scanActor.scanAllStream(at: path) {
                        let updatedResult = ScanResult(
                            url: result.url,
                            size: result.size,
                            category: .browserCache, // sticking to existing categories
                            lastModified: result.lastModified,
                            creationDate: result.creationDate,
                            appName: result.appName
                        )
                        allResults.append(updatedResult)
                    }
                } else {
                    do {
                        let keys: Set<URLResourceKey> = [
                            .fileSizeKey,
                            .totalFileAllocatedSizeKey,
                            .contentModificationDateKey
                        ]
                        let values = try path.resourceValues(forKeys: keys)
                        let size = values.totalFileAllocatedSize ?? values.fileSize ?? 0
                        if size > 0 {
                            let result = ScanResult(
                                url: path,
                                size: Int64(size),
                                category: .browserCache,
                                lastModified: values.contentModificationDate,
                                creationDate: nil,
                                appName: nil
                            )
                            allResults.append(result)
                        }
                    } catch {
                        // ignore error
                    }
                }
            }
        }

        return ModuleResult(moduleName: "Privacy", results: allResults)
    }
}
