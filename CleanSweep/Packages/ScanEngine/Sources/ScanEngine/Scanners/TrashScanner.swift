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

        return ModuleResult(moduleName: "Trash", results: allResults)
    }
}
