@testable import PlainCore
import Foundation
import SwiftData
import Testing

private func makeTempStore() throws -> (WidgetActionStore, URL) {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return (WidgetActionStore(directoryURL: directory), directory)
}

@Test
func widgetActionStoreEnqueueAndLoadRoundTrip() throws {
    let (store, directory) = try makeTempStore()
    defer { try? FileManager.default.removeItem(at: directory) }

    let action = WidgetToggleAction(id: UUID(), taskID: UUID(), desiredCompleted: true, createdAt: Date())
    try store.enqueue(action)

    let pending = store.pendingActions()
    #expect(pending.count == 1)
    #expect(pending.first?.id == action.id)
    #expect(pending.first?.taskID == action.taskID)
    #expect(pending.first?.desiredCompleted == true)
}

@Test
func widgetActionStoreSortsByCreatedAt() throws {
    let (store, directory) = try makeTempStore()
    defer { try? FileManager.default.removeItem(at: directory) }

    let older = WidgetToggleAction(id: UUID(), taskID: UUID(), desiredCompleted: true,
                                   createdAt: Date(timeIntervalSince1970: 100))
    let newer = WidgetToggleAction(id: UUID(), taskID: UUID(), desiredCompleted: false,
                                   createdAt: Date(timeIntervalSince1970: 200))
    try store.enqueue(newer)
    try store.enqueue(older)

    #expect(store.pendingActions().map(\.id) == [older.id, newer.id])
}

@Test
func widgetActionStoreDeletesCorruptFiles() throws {
    let (store, directory) = try makeTempStore()
    defer { try? FileManager.default.removeItem(at: directory) }

    let corruptURL = directory.appendingPathComponent("\(UUID().uuidString).json")
    try Data("not json".utf8).write(to: corruptURL)

    #expect(store.pendingActions().isEmpty)
    #expect(!FileManager.default.fileExists(atPath: corruptURL.path))
}

@Test
func widgetActionStoreRemoveDeletesFile() throws {
    let (store, directory) = try makeTempStore()
    defer { try? FileManager.default.removeItem(at: directory) }

    let action = WidgetToggleAction(id: UUID(), taskID: UUID(), desiredCompleted: true, createdAt: Date())
    try store.enqueue(action)
    store.remove(action)

    #expect(store.pendingActions().isEmpty)
}

@MainActor
@Test
func applyPendingActionsCompletesItemAndConsumesFile() throws {
    let (store, directory) = try makeTempStore()
    defer { try? FileManager.default.removeItem(at: directory) }

    let container = try SharedContainer.makeInMemoryContainer()
    let context = ModelContext(container)
    let item = TodoItem(title: "タスク")
    context.insert(item)
    try context.save()

    let action = WidgetToggleAction(id: UUID(), taskID: item.id, desiredCompleted: true,
                                    createdAt: Date(timeIntervalSince1970: 1_000))
    try store.enqueue(action)

    let consumed = store.applyPendingActions(context: context)

    #expect(consumed == 1)
    #expect(item.isCompleted == true)
    #expect(item.completedAt == Date(timeIntervalSince1970: 1_000))
    #expect(store.pendingActions().isEmpty)
}

@MainActor
@Test
func applyPendingActionsReopensItem() throws {
    let (store, directory) = try makeTempStore()
    defer { try? FileManager.default.removeItem(at: directory) }

    let container = try SharedContainer.makeInMemoryContainer()
    let context = ModelContext(container)
    let item = TodoItem(title: "タスク")
    item.isCompleted = true
    item.completedAt = Date()
    context.insert(item)
    try context.save()

    let action = WidgetToggleAction(id: UUID(), taskID: item.id, desiredCompleted: false, createdAt: Date())
    try store.enqueue(action)

    let consumed = store.applyPendingActions(context: context)

    #expect(consumed == 1)
    #expect(item.isCompleted == false)
    #expect(item.completedAt == nil)
}

@MainActor
@Test
func applyPendingActionsConsumesActionForMissingTask() throws {
    let (store, directory) = try makeTempStore()
    defer { try? FileManager.default.removeItem(at: directory) }

    let container = try SharedContainer.makeInMemoryContainer()
    let context = ModelContext(container)

    let action = WidgetToggleAction(id: UUID(), taskID: UUID(), desiredCompleted: true, createdAt: Date())
    try store.enqueue(action)

    let consumed = store.applyPendingActions(context: context)

    #expect(consumed == 1)
    #expect(store.pendingActions().isEmpty)
}

@MainActor
@Test
func applyPendingActionsWithEmptyDirectoryIsNoOp() throws {
    let (store, directory) = try makeTempStore()
    defer { try? FileManager.default.removeItem(at: directory) }

    let container = try SharedContainer.makeInMemoryContainer()
    let context = ModelContext(container)

    #expect(store.applyPendingActions(context: context) == 0)
}
