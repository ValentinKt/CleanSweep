import Foundation

public actor DevelopmentJunkScanner: ModuleScanner {
    private let scanActor = ScanActor()

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let targetDirs = Self.targetDirectories(fileManager: fileManager)

        var allResults: [ScanResult] = []

        for dir in targetDirs {
            for await result in await scanActor.scanStream(at: dir) {
                allResults.append(result)
            }
        }

        return ModuleResult(moduleName: "Developer Junk", results: allResults)
    }

    public static func targetDirectories(
        fileManager: FileManager = .default,
        homeDirectory: URL? = nil
    ) -> [URL] {
        let homeDir = homeDirectory ?? fileManager.homeDirectoryForCurrentUser
        var candidates = [
            homeDir.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
            homeDir.appendingPathComponent("Library/Developer/Xcode/Archives"),
            homeDir.appendingPathComponent("Library/Developer/CoreSimulator/Caches"),
            homeDir.appendingPathComponent("Library/Caches/org.swift.swiftpm"),
            homeDir.appendingPathComponent(".cache/org.swift.swiftpm"),
            homeDir.appendingPathComponent("Library/Caches/CocoaPods"),
            homeDir.appendingPathComponent("Library/Caches/org.carthage.CarthageKit")
        ]

        let simulatorDevicesRoot = homeDir.appendingPathComponent("Library/Developer/CoreSimulator/Devices")

        if let deviceDirectories = try? fileManager.contentsOfDirectory(
            at: simulatorDevicesRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for deviceDirectory in deviceDirectories {
                guard isDirectory(deviceDirectory, using: fileManager) else { continue }

                candidates.append(deviceDirectory.appendingPathComponent("data/Library/Caches"))
                candidates.append(deviceDirectory.appendingPathComponent("data/Library/Logs"))
                candidates.append(deviceDirectory.appendingPathComponent("data/tmp"))
            }
        }

        var seenPaths = Set<String>()

        return candidates
            .filter { isDirectory($0, using: fileManager) }
            .filter { seenPaths.insert($0.standardizedFileURL.path).inserted }
            .sorted { lhs, rhs in
                lhs.path.localizedStandardCompare(rhs.path) == .orderedAscending
            }
    }

    nonisolated private static func isDirectory(_ url: URL, using fileManager: FileManager) -> Bool {
        var isDirectoryFlag: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectoryFlag) && isDirectoryFlag.boolValue
    }
}
