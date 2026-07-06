import Foundation
import PlainCore

struct SyncSnapshotEntry: Codable, Equatable {
    var reminderExternalID: String
    var fingerprint: String
    var plainUpdatedAt: Date?
    var reminderUpdatedAt: Date?
    var lastSyncedAt: Date?

    init(reminderExternalID: String,
         fingerprint: String,
         plainUpdatedAt: Date? = nil,
         reminderUpdatedAt: Date? = nil,
         lastSyncedAt: Date? = nil) {
        self.reminderExternalID = reminderExternalID
        self.fingerprint = fingerprint
        self.plainUpdatedAt = plainUpdatedAt
        self.reminderUpdatedAt = reminderUpdatedAt
        self.lastSyncedAt = lastSyncedAt
    }
}

final class SyncSnapshotStore {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    static func defaultURL() -> URL {
        if let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedContainer.appGroupIdentifier)?
            .appendingPathComponent("ReminderSyncSnapshot.json") {
            return url
        }

        return FileManager.default.temporaryDirectory
            .appendingPathComponent("Plain")
            .appendingPathComponent("ReminderSyncSnapshot.json")
    }

    func load() -> [UUID: SyncSnapshotEntry] {
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder.reminderSync.decode([UUID: SyncSnapshotEntry].self, from: data) else {
            return [:]
        }
        return entries
    }

    func save(_ entries: [UUID: SyncSnapshotEntry]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder.reminderSync.encode(entries)
        try data.write(to: fileURL, options: [.atomic])
    }
}

private extension JSONEncoder {
    static var reminderSync: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var reminderSync: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
