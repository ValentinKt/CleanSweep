import Foundation

public actor ScreenshotScanner: ModuleScanner {
    private let scanActor = ScanActor()

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDirs = [
            homeDir.appendingPathComponent("Desktop"),
            homeDir.appendingPathComponent("Documents")
        ]

        var allResults: [ScanResult] = []

        for dir in targetDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                for await result in await scanActor.scanAllStream(at: dir) {
                    let filename = result.url.lastPathComponent.lowercased()

                    var isScreenshot = false
                    var isRecording = false

                    if filename.contains("screenshot") && (filename.hasSuffix(".png") || filename.hasSuffix(".jpg") || filename.hasSuffix(".jpeg")) {
                        isScreenshot = true
                    } else if filename.contains("screen recording") && (filename.hasSuffix(".mov") || filename.hasSuffix(".mp4")) {
                        isRecording = true
                    }

                    if isScreenshot || isRecording {
                        let category: FileCategory = isScreenshot ? .screenshot : .screenRecording
                        let updatedResult = ScanResult(
                            url: result.url,
                            size: result.size,
                            category: category,
                            lastModified: result.lastModified,
                            creationDate: result.creationDate,
                            appName: result.appName
                        )
                        allResults.append(updatedResult)
                    }
                }
            }
        }

        return ModuleResult(moduleName: "Screenshots & Recordings", results: allResults)
    }
}
