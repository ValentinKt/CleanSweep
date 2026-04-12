import Foundation
import CryptoKit

public actor DuplicateFinderScanner: ModuleScanner {
    private let scanActor = ScanActor()

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDirs = [
            homeDir.appendingPathComponent("Documents"),
            homeDir.appendingPathComponent("Downloads"),
            homeDir.appendingPathComponent("Desktop")
        ]

        var sizeMap: [Int64: [ScanResult]] = [:]

        for dir in targetDirs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: dir.path, isDirectory: &isDirectory), isDirectory.boolValue {
                for await result in await scanActor.scanAllStream(at: dir) {
                    if result.size > 0 {
                        sizeMap[result.size, default: []].append(result)
                    }
                }
            }
        }

        // Filter out unique sizes
        let potentialDuplicates = sizeMap.filter { $0.value.count > 1 }

        var duplicates: [ScanResult] = []
        let categorizer = Categorizer()

        for (_, files) in potentialDuplicates {
            try Task.checkCancellation()

            var hashMap: [String: [ScanResult]] = [:]

            for file in files {
                try Task.checkCancellation()
                publishScanPath(file.url.path)
                if let hash = await hashFile(url: file.url) {
                    hashMap[hash, default: []].append(file)
                }
            }

            for (_, hashedFiles) in hashMap where hashedFiles.count > 1 {
                // Add all to duplicates except the first one (we assume the first one is the original)
                // Actually, let's just add all of them so the user can choose which to delete.
                for file in hashedFiles {
                    let baseResult = ScanResult(
                        url: file.url,
                        size: file.size,
                        category: .duplicate,
                        lastModified: file.lastModified,
                        creationDate: file.creationDate,
                        appName: file.appName
                    )
                    let duplicateResult = ScanResult(
                        url: baseResult.url,
                        size: baseResult.size,
                        category: baseResult.category,
                        lastModified: baseResult.lastModified,
                        creationDate: baseResult.creationDate,
                        appName: baseResult.appName,
                        severity: categorizer.severity(for: baseResult),
                        isSafeToDelete: categorizer.isSafeToDelete(for: baseResult)
                    )
                    duplicates.append(duplicateResult)
                }
            }
        }

        return ModuleResult(moduleName: "Duplicates", results: duplicates)
    }

    private func hashFile(url: URL) async -> String? {
        return await Task.detached(priority: .utility) {
            do {
                let fileHandle = try FileHandle(forReadingFrom: url)
                defer { try? fileHandle.close() }

                var hasher = SHA256()
                let chunkSize = 1024 * 1024 // 1MB chunks

                var chunks = 0

                while let data = try fileHandle.read(upToCount: chunkSize), !data.isEmpty {
                    guard !Task.isCancelled else { return nil }
                    hasher.update(data: data)
                    chunks += 1
                    if chunks % 100 == 0 {
                        await Task.yield()
                    }
                }

                return hasher.finalize().map { String(format: "%02x", $0) }.joined()
            } catch {
                return nil
            }
        }.value
    }
}
