import Foundation

public actor ScanActor {
    private let categorizer = Categorizer()
    
    public init() {}
    
    public func scanStream(at root: URL) -> AsyncStream<ScanResult> {
        AsyncStream { continuation in
            Task.detached(priority: .utility) {
                let keys: [URLResourceKey] = [
                    .fileSizeKey,
                    .totalFileAllocatedSizeKey,
                    .contentModificationDateKey,
                    .contentAccessDateKey,
                    .isDirectoryKey,
                    .isSymbolicLinkKey,
                    .isPackageKey
                ]
                
                let enumerator = FileManager.default.enumerator(
                    at: root,
                    includingPropertiesForKeys: keys,
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                )
                
                let localCategorizer = Categorizer()
                
                while let url = enumerator?.nextObject() as? URL {
                    guard !Task.isCancelled else { break }
                    
                    do {
                        let values = try url.resourceValues(forKeys: Set(keys))
                        
                        if let isDir = values.isDirectory, isDir { continue }
                        if let isSym = values.isSymbolicLink, isSym { continue }
                        
                        let size = values.totalFileAllocatedSize ?? values.fileSize ?? 0
                        guard size > 0 else { continue }
                        
                        if let category = await localCategorizer.category(for: url, attributes: values) {
                            let result = ScanResult(
                                url: url,
                                size: Int64(size),
                                category: category,
                                lastModified: values.contentModificationDate,
                                creationDate: nil,
                                appName: nil
                            )
                            continuation.yield(result)
                        }
                    } catch {
                        // Log error internally if needed
                        continue
                    }
                }
                continuation.finish()
            }
        }
    }
}
