import Foundation
import SwiftData

public enum SharedContainer {
    public static let appGroupIdentifier = "group.com.KaiseiMachii.Plain"

    public static func makeSharedContainer() throws -> ModelContainer {
        let schema = Schema([TodoItem.self, Tag.self])
        let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
            .appendingPathComponent("Plain.sqlite")
        let config = ModelConfiguration(schema: schema, url: url)

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: PlainMigrationPlan.self,
                configurations: [config]
            )
            try validateStore(container)
            return container
        } catch {
            guard isMissingTagTable(error) else { throw error }
            try backupAndResetStore(at: url)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: PlainMigrationPlan.self,
                configurations: [config]
            )
            try validateStore(container)
            return container
        }
    }

    public static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([TodoItem.self, Tag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private static func validateStore(_ container: ModelContainer) throws {
        let context = ModelContext(container)
        let tags = try context.fetch(FetchDescriptor<Tag>())
        _ = tags.count
    }

    private static func isMissingTagTable(_ error: Error) -> Bool {
        if String(describing: error).localizedCaseInsensitiveContains("no such table: ztag") {
            return true
        }

        let nsError = error as NSError
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
           String(describing: underlying).localizedCaseInsensitiveContains("no such table: ztag") {
            return true
        }

        if let detailed = nsError.userInfo["NSDetailedErrors"] as? [NSError] {
            for e in detailed {
                if String(describing: e).localizedCaseInsensitiveContains("no such table: ztag") {
                    return true
                }
            }
        }

        return false
    }

    private static func backupAndResetStore(at url: URL) throws {
        let fm = FileManager.default
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")

        let baseDir = url.deletingLastPathComponent()
        let backupDir = baseDir.appendingPathComponent("PlainStoreBackup-\(timestamp)", isDirectory: true)
        try fm.createDirectory(at: backupDir, withIntermediateDirectories: true)

        for storeURL in candidateStoreFiles(for: url) {
            guard fm.fileExists(atPath: storeURL.path) else { continue }
            let backupURL = backupDir.appendingPathComponent(storeURL.lastPathComponent)
            try? fm.removeItem(at: backupURL)
            try fm.copyItem(at: storeURL, to: backupURL)
            try fm.removeItem(at: storeURL)
        }
    }

    private static func candidateStoreFiles(for baseURL: URL) -> [URL] {
        [
            baseURL,
            URL(fileURLWithPath: baseURL.path + "-shm"),
            URL(fileURLWithPath: baseURL.path + "-wal")
        ]
    }
}

