import Foundation

public actor DevelopmentJunkScanner: ModuleScanner {
    private let scanActor = ScanActor()

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDirs = [
            homeDir.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
            homeDir.appendingPathComponent("Library/Developer/Xcode/Archives"),
            homeDir.appendingPathComponent("Library/Developer/CoreSimulator/Devices"),
            homeDir.appendingPathComponent("Library/Caches/org.swift.swiftpm"),
            homeDir.appendingPathComponent(".cache/org.swift.swiftpm"),
            homeDir.appendingPathComponent("Library/Caches/CocoaPods"),
            homeDir.appendingPathComponent("Library/Caches/org.carthage.CarthageKit")
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

        return ModuleResult(moduleName: "Developer Junk", results: allResults)
    }
}
