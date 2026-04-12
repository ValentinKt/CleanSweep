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
