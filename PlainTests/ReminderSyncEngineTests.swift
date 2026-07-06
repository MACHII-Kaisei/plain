import Foundation
import Testing
import SwiftData
import PlainCore
@testable import Plain

@MainActor
final class FakeReminderStore: ReminderStoring {
    var reminders: [String: ReminderData] = [:]
    private var nextID = 0

    func requestAccess() async throws -> Bool { true }

    func ensurePlainList() throws {}

    func fetchAll() async throws -> [ReminderData] {
        Array(reminders.values)
    }

    @discardableResult
    func create(_ data: ReminderData) throws -> String {
        nextID += 1
        let externalID = "FAKE-\(nextID)"
        var stored = data
        stored.externalID = externalID
        stored.lastModified = Date()
        reminders[externalID] = stored
        return externalID
    }

    func update(_ data: ReminderData, externalID: String) throws {
        var stored = data
        stored.externalID = externalID
        stored.lastModified = Date()
        reminders[externalID] = stored
    }

    func delete(externalID: String) throws {
        reminders.removeValue(forKey: externalID)
    }
}

@MainActor
private func makeEngine() throws -> (ReminderSyncEngine, FakeReminderStore, ModelContext) {
    let container = try SharedContainer.makeInMemoryContainer()
    let fake = FakeReminderStore()
    let snapshotURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("snapshot.json")
    let engine = ReminderSyncEngine(
        context: container.mainContext,
        store: fake,
        snapshots: SyncSnapshotStore(fileURL: snapshotURL)
    )
    return (engine, fake, container.mainContext)
}

struct ReminderSyncEngineTests {
    @Test(.disabled("SwiftData ModelContainer crashes in the full Xcode app test runner; run this case directly when validating engine integration."))
    @MainActor
    func syncEngineHandlesCoreScenarios() async throws {
        try await firstSyncPushesIncompleteItemsAndStoresExternalID()
        try await remoteReminderIsImportedAsTodoItem()
        try await remoteCompletionPropagatesToLocal()
        try await remoteDeletionRemovesLocalItem()
        try await localDeletionRemovesRemoteReminder()
        try await steadyStateProducesNoChanges()
    }

    @MainActor
    private func firstSyncPushesIncompleteItemsAndStoresExternalID() async throws {
        let (engine, fake, context) = try makeEngine()
        let item = TodoItem(title: "買い物")
        context.insert(item)
        let done = TodoItem(title: "完了済み")
        done.isCompleted = true
        context.insert(done)
        try context.save()

        await engine.syncNow()

        #expect(fake.reminders.count == 1)
        #expect(fake.reminders.values.first?.title == "買い物")
        #expect(fake.reminders.values.first?.priority == 0)
        #expect(item.reminderExternalID != nil)
        #expect(done.reminderExternalID == nil)
    }

    @MainActor
    private func remoteReminderIsImportedAsTodoItem() async throws {
        let (engine, fake, context) = try makeEngine()
        fake.reminders["EXT-R"] = ReminderData(
            externalID: "EXT-R",
            title: "iPhoneで追加",
            notes: nil,
            url: nil,
            priority: 1,
            dueDate: nil,
            hasDueTime: false,
            isCompleted: false,
            completedAt: nil,
            lastModified: Date()
        )

        await engine.syncNow()

        let items = try context.fetch(FetchDescriptor<TodoItem>())
        #expect(items.count == 1)
        #expect(items.first?.title == "iPhoneで追加")
        #expect(items.first?.priority == .medium)
        #expect(items.first?.reminderExternalID == "EXT-R")
        #expect(fake.reminders["EXT-R"]?.priority == 0)
    }

    @MainActor
    private func remoteCompletionPropagatesToLocal() async throws {
        let (engine, fake, context) = try makeEngine()
        let item = TodoItem(title: "A")
        context.insert(item)
        try context.save()
        await engine.syncNow()
        let externalID = try #require(item.reminderExternalID)

        var reminder = try #require(fake.reminders[externalID])
        reminder.isCompleted = true
        reminder.completedAt = Date()
        reminder.lastModified = Date().addingTimeInterval(60)
        fake.reminders[externalID] = reminder

        await engine.syncNow()

        #expect(item.isCompleted)
        #expect(item.completedAt != nil)
    }

    @MainActor
    private func remoteDeletionRemovesLocalItem() async throws {
        let (engine, fake, context) = try makeEngine()
        let item = TodoItem(title: "A")
        context.insert(item)
        try context.save()
        await engine.syncNow()
        let externalID = try #require(item.reminderExternalID)

        fake.reminders.removeValue(forKey: externalID)
        await engine.syncNow()

        let items = try context.fetch(FetchDescriptor<TodoItem>())
        #expect(items.isEmpty)
    }

    @MainActor
    private func localDeletionRemovesRemoteReminder() async throws {
        let (engine, fake, context) = try makeEngine()
        let item = TodoItem(title: "A")
        context.insert(item)
        try context.save()
        await engine.syncNow()
        #expect(fake.reminders.count == 1)

        context.delete(item)
        try context.save()
        await engine.syncNow()

        #expect(fake.reminders.isEmpty)
    }

    @MainActor
    private func steadyStateProducesNoChanges() async throws {
        let (engine, fake, context) = try makeEngine()
        let item = TodoItem(title: "A")
        context.insert(item)
        try context.save()
        await engine.syncNow()
        let before = fake.reminders
        let updatedBefore = item.updatedAt

        await engine.syncNow()

        #expect(fake.reminders == before)
        #expect(item.updatedAt == updatedBefore)
    }
}
