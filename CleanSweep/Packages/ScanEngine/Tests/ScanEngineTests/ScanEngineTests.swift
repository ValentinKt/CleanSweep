import Foundation
import Testing
@testable import ScanEngine

@Test func developmentJunkTargetsOnlyCuratedDirectories() async throws {
    let fileManager = FileManager.default
    let homeDirectory = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)

    let expectedDirectories = [
        "Library/Developer/Xcode/DerivedData",
        "Library/Developer/Xcode/Archives",
        "Library/Developer/CoreSimulator/Caches",
        "Library/Caches/org.swift.swiftpm",
        ".cache/org.swift.swiftpm",
        "Library/Caches/CocoaPods",
        "Library/Caches/org.carthage.CarthageKit",
        "Library/Developer/CoreSimulator/Devices/DEVICE-A/data/Library/Caches",
        "Library/Developer/CoreSimulator/Devices/DEVICE-A/data/Library/Logs",
        "Library/Developer/CoreSimulator/Devices/DEVICE-A/data/tmp"
    ]

    for relativePath in expectedDirectories {
        try fileManager.createDirectory(
            at: homeDirectory.appendingPathComponent(relativePath),
            withIntermediateDirectories: true
        )
    }

    try fileManager.createDirectory(
        at: homeDirectory.appendingPathComponent(
            "Library/Developer/CoreSimulator/Devices/DEVICE-A/data/Containers/Data/Application"
        ),
        withIntermediateDirectories: true
    )

    defer {
        try? fileManager.removeItem(at: homeDirectory)
    }

    let directories = DevelopmentJunkScanner.targetDirectories(
        fileManager: fileManager,
        homeDirectory: homeDirectory
    )

    let homePath = homeDirectory.standardizedFileURL.path
    let scannedPaths = Set(
        directories.map { directory in
            directory.standardizedFileURL.path.replacingOccurrences(of: homePath + "/", with: "")
        }
    )

    #expect(scannedPaths == Set(expectedDirectories))
    #expect(!scannedPaths.contains("Library/Developer/CoreSimulator/Devices"))
    #expect(
        !scannedPaths.contains(
            "Library/Developer/CoreSimulator/Devices/DEVICE-A/data/Containers/Data/Application"
        )
    )
}

@Test func developmentJunkAggregatesHeavyDirectoriesIntoReviewableEntries() async throws {
    let fileManager = FileManager.default
    let homeDirectory = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)

    defer {
        try? fileManager.removeItem(at: homeDirectory)
    }

    try createDevelopmentJunkFixture(at: homeDirectory, fileManager: fileManager)

    let scanner = DevelopmentJunkScanner()
    let scanResult = try await scanner.scanSnapshot(
        fileManager: fileManager,
        homeDirectory: homeDirectory
    )
    let results = scanResult.results

    let resultPaths = Set(results.map { $0.url.lastPathComponent })

    #expect(resultPaths.contains("App-123"))
    #expect(resultPaths.contains("Caches"))
    #expect(resultPaths.contains("repositories"))
    #expect(results.count == 3)

    let derivedDataResult = try #require(
        results.first(where: { $0.url.lastPathComponent == "App-123" })
    )
    #expect(derivedDataResult.category == FileCategory.xcodeDerivedData)
    #expect(derivedDataResult.isSafeToDelete)
    #expect(derivedDataResult.size >= 6_144)
}

private func createDevelopmentJunkFixture(at homeDirectory: URL, fileManager: FileManager) throws {
    let derivedDataProject = homeDirectory
        .appendingPathComponent("Library/Developer/Xcode/DerivedData/App-123")
    let simulatorCache = homeDirectory
        .appendingPathComponent("Library/Developer/CoreSimulator/Devices/DEVICE-A/data/Library/Caches")
    let spmCache = homeDirectory
        .appendingPathComponent("Library/Caches/org.swift.swiftpm/repositories")

    try fileManager.createDirectory(at: derivedDataProject, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: simulatorCache, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: spmCache, withIntermediateDirectories: true)

    let files: [(URL, Data)] = [
        (
            derivedDataProject.appendingPathComponent("Index.noindex/records/a.record"),
            Data(repeating: 0x1, count: 4_096)
        ),
        (
            derivedDataProject.appendingPathComponent("Build/Products/app.o"),
            Data(repeating: 0x2, count: 2_048)
        ),
        (
            simulatorCache.appendingPathComponent("com.example.bundle/cache.db"),
            Data(repeating: 0x3, count: 1_024)
        ),
        (
            spmCache.appendingPathComponent("package-cache.bin"),
            Data(repeating: 0x4, count: 512)
        )
    ]

    for (url, data) in files {
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url)
    }
}
