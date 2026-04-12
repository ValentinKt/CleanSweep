import Foundation

public actor LargeFilesScanner: ModuleScanner {
    private let scanActor = ScanActor()
    private let sizeThreshold: Int64 = 100 * 1024 * 1024 // 100 MB
    private let ageThreshold: TimeInterval = 365 * 24 * 60 * 60 // 1 year

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let targetDirs = [
            homeDir.appendingPathComponent("Documents"),
            homeDir.appendingPathComponent("Downloads"),
            homeDir.appendingPathComponent("Desktop"),
            homeDir.appendingPathComponent("Movies"),
            homeDir.appendingPathComponent("Music")
        ]

        var allResults: [ScanResult] = []
        let now = Date()

        for dir in targetDirs {
            try Task.checkCancellation()
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let categorizer = Categorizer()
                for await result in await scanActor.scanStream(at: dir) {
                    try Task.checkCancellation()
                    // Filter based on size or age
                    let isLarge = result.size >= sizeThreshold
                    let isOld = result.lastModified.map { now.timeIntervalSince($0) > ageThreshold } ?? false

                    if isLarge || isOld {
                        // Let's create a new result with correct category if needed
                        let category: FileCategory = isLarge ? .largeFile : .oldFile
                        let baseResult = ScanResult(
                            url: result.url,
                            size: result.size,
                            category: category,
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
        }

        return ModuleResult(moduleName: "Large & Old Files", results: allResults)
    }
}
