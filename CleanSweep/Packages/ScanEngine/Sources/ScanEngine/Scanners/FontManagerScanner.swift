import Foundation

public actor FontManagerScanner: ModuleScanner {
    private let scanActor = ScanActor()

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDirs = [
            homeDir.appendingPathComponent("Library/Fonts")
        ]

        var allResults: [ScanResult] = []
        let categorizer = Categorizer()

        for dir in targetDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                for await result in await scanActor.scanStream(at: dir) {
                    let baseResult = ScanResult(
                        url: result.url,
                        size: result.size,
                        category: .fontDuplicate,
                        lastModified: result.lastModified,
                        creationDate: result.creationDate,
                        appName: result.appName
                    )
                    let updatedResult = ScanResult(
                        url: baseResult.url,
                        size: baseResult.size,
                        category: baseResult.category,
                        lastModified: baseResult.lastModified,
                        creationDate: baseResult.creationDate,
                        appName: baseResult.appName,
                        severity: categorizer.severity(for: baseResult),
                        isSafeToDelete: categorizer.isSafeToDelete(for: baseResult)
                    )
                    allResults.append(updatedResult)
                }
            }
        }

        return ModuleResult(moduleName: "Font Manager", results: allResults)
    }
}
