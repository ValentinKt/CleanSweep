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

        for dir in targetDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                for await result in await scanActor.scanAllStream(at: dir) {
                    let updatedResult = ScanResult(
                        url: result.url,
                        size: result.size,
                        category: .fontDuplicate,
                        lastModified: result.lastModified,
                        creationDate: result.creationDate,
                        appName: result.appName
                    )
                    allResults.append(updatedResult)
                }
            }
        }

        return ModuleResult(moduleName: "Font Manager", results: allResults)
    }
}
