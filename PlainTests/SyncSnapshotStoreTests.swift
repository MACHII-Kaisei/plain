import Foundation
import Testing
@testable import Plain

struct SyncSnapshotStoreTests {
    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("snapshot.json")
    }

    @Test
    func saveAndLoadRoundTrip() throws {
        let store = SyncSnapshotStore(fileURL: makeTempURL())
        let id = UUID()
        let entries = [
            id: SyncSnapshotEntry(
                reminderExternalID: "EXT",
                fingerprint: "fp",
                plainUpdatedAt: Date(timeIntervalSince1970: 10),
                reminderUpdatedAt: Date(timeIntervalSince1970: 20),
                lastSyncedAt: Date(timeIntervalSince1970: 30)
            ),
        ]

        try store.save(entries)

        #expect(store.load() == entries)
    }

    @Test
    func loadReturnsEmptyWhenFileMissing() {
        let store = SyncSnapshotStore(fileURL: makeTempURL())
        #expect(store.load().isEmpty)
    }

    @Test
    func loadReturnsEmptyWhenFileCorrupted() throws {
        let url = makeTempURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not json".utf8).write(to: url)

        let store = SyncSnapshotStore(fileURL: url)

        #expect(store.load().isEmpty)
    }
}
