import Foundation

public actor SystemJunkScanner: ModuleScanner {
    private let scanActor = ScanActor()

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDirs: [URL] = [
            homeDir.appendingPathComponent("Library/Caches"),
            homeDir.appendingPathComponent("Library/Logs")
        ]

        var allResults: [ScanResult] = []

        for dir in targetDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                for await result in await scanActor.scanStream(at: dir) {
                    allResults.append(result)
                }
            }
        }

        return ModuleResult(moduleName: "System Junk", results: allResults)
    }
}
