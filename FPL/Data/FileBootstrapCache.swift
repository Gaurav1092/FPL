import Foundation

/// Keeps the last successful `bootstrap-static` payload on disk so the app can launch offline.
///
/// The file lives in Application Support rather than Caches because the system can purge
/// Caches, which would break offline launch. It's excluded from backups because it can always
/// be downloaded again.
struct FileBootstrapCache: Sendable {
    struct Entry: Equatable, Sendable {
        let data: Data
        let savedAt: Date
    }

    let fileURL: URL

    static func makeDefault() -> FileBootstrapCache {
        let directory = (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.temporaryDirectory
        return FileBootstrapCache(fileURL: directory.appendingPathComponent("bootstrap-static.json"))
    }

    func load() throws -> Entry? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        let data = try Data(contentsOf: fileURL)
        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        let savedAt = attributes[.modificationDate] as? Date ?? .distantPast
        return Entry(data: data, savedAt: savedAt)
    }

    /// Writes atomically, so a crash mid-write can't leave a half-written file behind.
    /// The save time is stored as the file's modification date.
    func save(_ data: Data, savedAt: Date) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        try fileManager.setAttributes([.modificationDate: savedAt], ofItemAtPath: fileURL.path)

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var url = fileURL
        try url.setResourceValues(resourceValues)
    }
}
