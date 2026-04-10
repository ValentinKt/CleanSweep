import Foundation

public actor MailAttachmentScanner: ModuleScanner {
    private let scanActor = ScanActor()

    public init() {}

    public func scan() async throws -> ModuleResult {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser

        let targetDir = homeDir.appendingPathComponent("Library/Containers/com.apple.mail/Data/Library/Mail Downloads")

        var allResults: [ScanResult] = []

        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: targetDir.path, isDirectory: &isDirectory), isDirectory.boolValue {
            for await result in await scanActor.scanAllStream(at: targetDir) {
                let updatedResult = ScanResult(
                    url: result.url,
                    size: result.size,
                    category: .mailAttachment,
                    lastModified: result.lastModified,
                    creationDate: result.creationDate,
                    appName: result.appName
                )
                allResults.append(updatedResult)
            }
        }

        return ModuleResult(moduleName: "Mail Attachments", results: allResults)
    }
}
