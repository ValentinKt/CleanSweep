import Foundation

public actor NetworkCacheScanner: ModuleScanner {
    private let scanActor = ScanActor()

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDirs = [
            homeDir.appendingPathComponent("Library/Caches/com.apple.nsurlsessiond"),
            homeDir.appendingPathComponent("Library/Containers/com.apple.Safari/Data/Library/Caches"),
            homeDir.appendingPathComponent("Library/Caches/com.apple.Safari"),
            homeDir.appendingPathComponent("Library/Caches/Google/Chrome/Default/Cache"),
            homeDir.appendingPathComponent("Library/Caches/Firefox/Profiles")
        ]

        var allResults: [ScanResult] = []

        for dir in targetDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                for await result in await scanActor.scanAllStream(at: dir) {
                    let updatedResult = ScanResult(
                        url: result.url,
                        size: result.size,
                        category: .networkCache,
                        lastModified: result.lastModified,
                        creationDate: result.creationDate,
                        appName: result.appName
                    )
                    allResults.append(updatedResult)
                }
            }
        }

        return ModuleResult(moduleName: "Network Cache", results: allResults)
    }
}
