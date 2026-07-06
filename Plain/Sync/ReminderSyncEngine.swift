import Foundation
import SwiftData
import WidgetKit
import PlainCore

@MainActor
final class ReminderSyncEngine {
    private let context: ModelContext
    private let store: ReminderStoring
    private let snapshots: SyncSnapshotStore

    init(context: ModelContext, store: ReminderStoring, snapshots: SyncSnapshotStore) {
        self.context = context
        self.store = store
        self.snapshots = snapshots
    }

    func syncNow() async {
        do {
            try store.ensurePlainList()
            let remoteItems = try await store.fetchAll()
            let localItems = try context.fetch(FetchDescriptor<TodoItem>())
            let localItemsByID = Dictionary(uniqueKeysWithValues: localItems.map { ($0.id, $0) })
            let localStates = localItems.map(Self.localState)
            let actions = SyncPlanner.plan(
                local: localStates,
                remote: remoteItems,
                snapshot: snapshots.load()
            )

            var changedLocalData = false
            var hadActionFailure = false
            for action in actions {
                do {
                    let didChangeLocal = try apply(action, localItemsByID: localItemsByID)
                    changedLocalData = changedLocalData || didChangeLocal
                } catch {
                    print("[ReminderSync] action failed: \(action) \(error)")
                    ReminderSyncSettings.recordError(error.localizedDescription)
                    hadActionFailure = true
                }
            }

            if context.hasChanges {
                try context.save()
            }
            if hadActionFailure {
                ReminderSyncSettings.recordError("一部のタスクを同期できませんでした。次回同期で再試行します。")
            } else {
                try rebuildSnapshot()
                ReminderSyncSettings.recordSuccess()
            }

            if changedLocalData && !Self.isRunningTests {
                try? SharedWidgetSnapshotStore.write(from: context.container)
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            print("[ReminderSync] sync failed: \(error)")
            ReminderSyncSettings.recordError(error.localizedDescription)
        }
    }

    private func apply(_ action: SyncAction, localItemsByID: [UUID: TodoItem]) throws -> Bool {
        switch action {
        case .createRemote(let localID):
            guard let item = localItemsByID[localID] else { return false }
            let externalID = try store.create(ReminderMapper.data(from: item))
            item.reminderExternalID = externalID
            return true

        case .updateRemote(let localID, let externalID):
            guard let item = localItemsByID[localID] else { return false }
            try store.update(ReminderMapper.data(from: item), externalID: externalID)
            return false

        case .deleteRemote(let externalID):
            try store.delete(externalID: externalID)
            return false

        case .createLocal(let remote):
            let item = TodoItem(title: remote.title)
            ReminderMapper.apply(remote, to: item)
            context.insert(item)
            if let externalID = remote.externalID,
               ReminderMapper.shouldResetRemotePriority(remote) {
                try store.update(ReminderMapper.data(from: item), externalID: externalID)
            }
            return true

        case .updateLocal(let localID, let remote):
            guard let item = localItemsByID[localID] else { return false }
            ReminderMapper.apply(remote, to: item)
            return true

        case .deleteLocal(let localID):
            guard let item = localItemsByID[localID] else { return false }
            context.delete(item)
            return true
        }
    }

    private func rebuildSnapshot() throws {
        let now = Date()
        let items = try context.fetch(FetchDescriptor<TodoItem>())
        var entries: [UUID: SyncSnapshotEntry] = [:]
        for item in items {
            guard let externalID = item.reminderExternalID else { continue }
            entries[item.id] = SyncSnapshotEntry(
                reminderExternalID: externalID,
                fingerprint: ReminderMapper.fingerprint(of: ReminderMapper.data(from: item)),
                plainUpdatedAt: item.updatedAt,
                lastSyncedAt: now
            )
        }
        try snapshots.save(entries)
    }

    private static func localState(from item: TodoItem) -> LocalItemState {
        LocalItemState(
            id: item.id,
            externalID: item.reminderExternalID,
            fingerprint: ReminderMapper.fingerprint(of: ReminderMapper.data(from: item)),
            updatedAt: item.updatedAt,
            isCompleted: item.isCompleted
        )
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
