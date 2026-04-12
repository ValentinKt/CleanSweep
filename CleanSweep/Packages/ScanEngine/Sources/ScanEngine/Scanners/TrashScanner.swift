import Foundation

public actor TrashScanner: ModuleScanner {
    private let scanActor = ScanActor()

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDir = homeDir.appendingPathComponent(".Trash")

        var allResults: [ScanResult] = []

        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: targetDir.path, isDirectory: &isDirectory), isDirectory.boolValue {
            for await result in await scanActor.scanAllStream(at: targetDir) {
                let baseResult = ScanResult(
                    url: result.url,
                    size: result.size,
                    category: .trashItem,
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
                    severity: Categorizer().severity(for: baseResult),
                    isSafeToDelete: Categorizer().isSafeToDelete(for: baseResult)
                )
                allResults.append(updatedResult)
            }
        }

        return ModuleResult(moduleName: "Trash", results: allResults)
    }
}
