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
            homeDir.appendingPathComponent("Library/Caches/Google/Chrome"),
            homeDir.appendingPathComponent("Library/Caches/Firefox/Profiles"),
            homeDir.appendingPathComponent("Library/Caches/BraveSoftware"),
            homeDir.appendingPathComponent("Library/Caches/com.duckduckgo.macos.browser"),
            homeDir.appendingPathComponent("Library/Containers/com.duckduckgo.macos.browser/Data/Library/Caches"),
            homeDir.appendingPathComponent("Library/Caches/com.operasoftware.Opera"),
            homeDir.appendingPathComponent("Library/Caches/com.microsoft.edgemac"),
            homeDir.appendingPathComponent("Library/Caches/company.thebrowser.Browser"), // Arc
            homeDir.appendingPathComponent("Library/Caches/com.vivaldi.Vivaldi")
        ]

        var allResults: [ScanResult] = []

        for dir in targetDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                for await result in await scanActor.scanAllStream(at: dir) {
                    let updatedResult = ScanResult(
                        url: result.url,
                        size: result.size,
                        category: result.category,
                        lastModified: result.lastModified,
                        creationDate: result.creationDate,
                        appName: result.appName,
                        severity: Categorizer().severity(for: result),
                        isSafeToDelete: Categorizer().isSafeToDelete(for: result)
                    )
                    allResults.append(updatedResult)
                }
            }
        }

        return ModuleResult(moduleName: "Network Cache", results: allResults)
    }
}
