@testable import PlainCore
import Foundation
import Testing

@Test
func widgetSnapshotLoadPrefersReadableFileOverDefaults() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let fileURL = directory.appendingPathComponent("WidgetSnapshot.json")
    let suiteName = "PlainWidgetSnapshotStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
    }

    let fileCache = WidgetSnapshotCache(
        generatedAt: Date(timeIntervalSince1970: 1),
        todoItems: [
            WidgetTodoItemSnapshot(
                id: UUID(),
                title: "file",
                notes: nil,
                dueDate: nil,
                isCompleted: false,
                hasDueTime: false,
                tags: []
            ),
        ]
    )
    let defaultsCache = WidgetSnapshotCache(
        generatedAt: Date(timeIntervalSince1970: 2),
        todoItems: [
            WidgetTodoItemSnapshot(
                id: UUID(),
                title: "defaults",
                notes: nil,
                dueDate: nil,
                isCompleted: false,
                hasDueTime: false,
                tags: []
            ),
        ]
    )
    try JSONEncoder.plainWidgetSnapshotTest.encode(fileCache).write(to: fileURL)
    defaults.set(try JSONEncoder.plainWidgetSnapshotTest.encode(defaultsCache), forKey: "WidgetSnapshotData")

    let loaded = try SharedWidgetSnapshotStore.load(readableURLs: [fileURL], defaults: defaults)

    #expect(loaded.todoItems.map(\.title) == ["file"])
}

@Test
func applyingCompletionMarksOnlyMatchingItem() throws {
    let target = UUID()
    let other = UUID()
    let cache = WidgetSnapshotCache(
        generatedAt: Date(timeIntervalSince1970: 1),
        todoItems: [
            WidgetTodoItemSnapshot(id: target, title: "対象", notes: nil, dueDate: nil,
                                   isCompleted: false, hasDueTime: false, tags: []),
            WidgetTodoItemSnapshot(id: other, title: "他", notes: nil, dueDate: nil,
                                   isCompleted: false, hasDueTime: false, tags: []),
        ]
    )

    let now = Date(timeIntervalSince1970: 2)
    let updated = SharedWidgetSnapshotStore.applyingCompletion(
        to: cache, taskID: target, isCompleted: true, now: now
    )

    #expect(updated.generatedAt == now)
    #expect(updated.todoItems.first(where: { $0.id == target })?.isCompleted == true)
    #expect(updated.todoItems.first(where: { $0.id == other })?.isCompleted == false)
    #expect(updated.todoItems.map(\.title) == ["対象", "他"])
}

private extension JSONEncoder {
    static var plainWidgetSnapshotTest: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
