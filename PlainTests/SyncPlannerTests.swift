import Foundation
import Testing
@testable import Plain

@MainActor
struct SyncPlannerTests {
    private func remote(_ externalID: String,
                        title: String,
                        modified: Date = Date(timeIntervalSince1970: 1_000),
                        completed: Bool = false,
                        priority: Int = 0) -> ReminderData {
        ReminderData(
            externalID: externalID,
            title: title,
            notes: nil,
            url: nil,
            priority: priority,
            dueDate: nil,
            hasDueTime: false,
            isCompleted: completed,
            completedAt: nil,
            lastModified: modified
        )
    }

    private func local(_ id: UUID,
                       externalID: String? = nil,
                       title: String,
                       updated: Date = Date(timeIntervalSince1970: 1_000),
                       completed: Bool = false) -> LocalItemState {
        let data = ReminderData(
            externalID: externalID,
            title: title,
            notes: nil,
            url: nil,
            priority: 0,
            dueDate: nil,
            hasDueTime: false,
            isCompleted: completed,
            completedAt: nil,
            lastModified: updated
        )
        return LocalItemState(
            id: id,
            externalID: externalID,
            fingerprint: ReminderMapper.fingerprint(of: data),
            updatedAt: updated,
            isCompleted: completed
        )
    }

    private func fp(title: String, completed: Bool = false) -> String {
        ReminderMapper.fingerprint(of: ReminderData(
            externalID: nil,
            title: title,
            notes: nil,
            url: nil,
            priority: 0,
            dueDate: nil,
            hasDueTime: false,
            isCompleted: completed,
            completedAt: nil,
            lastModified: nil
        ))
    }

    @Test
    func firstSyncPushesOnlyIncompleteItems() {
        let activeID = UUID()
        let doneID = UUID()

        let actions = SyncPlanner.plan(
            local: [
                local(activeID, title: "未完了"),
                local(doneID, title: "完了済み", completed: true),
            ],
            remote: [],
            snapshot: [:]
        )

        #expect(actions == [.createRemote(localID: activeID)])
    }

    @Test
    func newRemoteReminderIsImported() {
        let reminder = remote("EXT-N", title: "iPhoneで追加")

        let actions = SyncPlanner.plan(local: [], remote: [reminder], snapshot: [:])

        #expect(actions == [.createLocal(remote: reminder)])
    }

    @Test
    func localEditPushesToRemote() {
        let id = UUID()
        let snapshot = [id: SyncSnapshotEntry(reminderExternalID: "E", fingerprint: fp(title: "旧"))]

        let actions = SyncPlanner.plan(
            local: [local(id, externalID: "E", title: "新")],
            remote: [remote("E", title: "旧")],
            snapshot: snapshot
        )

        #expect(actions == [.updateRemote(localID: id, externalID: "E")])
    }

    @Test
    func remoteEditPullsToLocal() {
        let id = UUID()
        let snapshot = [id: SyncSnapshotEntry(reminderExternalID: "E", fingerprint: fp(title: "旧"))]
        let reminder = remote("E", title: "新")

        let actions = SyncPlanner.plan(
            local: [local(id, externalID: "E", title: "旧")],
            remote: [reminder],
            snapshot: snapshot
        )

        #expect(actions == [.updateLocal(localID: id, remote: reminder)])
    }

    @Test
    func bothEditedNewerLocalWins() {
        let id = UUID()
        let snapshot = [id: SyncSnapshotEntry(reminderExternalID: "E", fingerprint: fp(title: "旧"))]

        let actions = SyncPlanner.plan(
            local: [local(id, externalID: "E", title: "ローカル", updated: Date(timeIntervalSince1970: 2_000))],
            remote: [remote("E", title: "リモート", modified: Date(timeIntervalSince1970: 1_500))],
            snapshot: snapshot
        )

        #expect(actions == [.updateRemote(localID: id, externalID: "E")])
    }

    @Test
    func bothEditedNewerRemoteWins() {
        let id = UUID()
        let snapshot = [id: SyncSnapshotEntry(reminderExternalID: "E", fingerprint: fp(title: "旧"))]
        let reminder = remote("E", title: "リモート", modified: Date(timeIntervalSince1970: 3_000))

        let actions = SyncPlanner.plan(
            local: [local(id, externalID: "E", title: "ローカル", updated: Date(timeIntervalSince1970: 2_000))],
            remote: [reminder],
            snapshot: snapshot
        )

        #expect(actions == [.updateLocal(localID: id, remote: reminder)])
    }

    @Test
    func localDeleteRemovesRemote() {
        let id = UUID()
        let snapshot = [id: SyncSnapshotEntry(reminderExternalID: "E", fingerprint: fp(title: "A"))]

        let actions = SyncPlanner.plan(local: [], remote: [remote("E", title: "A")], snapshot: snapshot)

        #expect(actions == [.deleteRemote(externalID: "E")])
    }

    @Test
    func remoteDeleteRemovesLocal() {
        let id = UUID()
        let snapshot = [id: SyncSnapshotEntry(reminderExternalID: "E", fingerprint: fp(title: "A"))]

        let actions = SyncPlanner.plan(
            local: [local(id, externalID: "E", title: "A")],
            remote: [],
            snapshot: snapshot
        )

        #expect(actions == [.deleteLocal(localID: id)])
    }

    @Test
    func deleteWinsOverEdit() {
        let id = UUID()
        let snapshot = [id: SyncSnapshotEntry(reminderExternalID: "E", fingerprint: fp(title: "旧"))]

        let actions = SyncPlanner.plan(
            local: [],
            remote: [remote("E", title: "編集済み", modified: Date(timeIntervalSince1970: 9_999))],
            snapshot: snapshot
        )

        #expect(actions == [.deleteRemote(externalID: "E")])
    }

    @Test
    func unchangedPairProducesNoActions() {
        let id = UUID()
        let snapshot = [id: SyncSnapshotEntry(reminderExternalID: "E", fingerprint: fp(title: "A"))]

        let actions = SyncPlanner.plan(
            local: [local(id, externalID: "E", title: "A")],
            remote: [remote("E", title: "A")],
            snapshot: snapshot
        )

        #expect(actions.isEmpty)
    }

    @Test
    func remotePriorityIsResetEvenWhenContentIsUnchanged() {
        let id = UUID()
        let snapshot = [id: SyncSnapshotEntry(reminderExternalID: "E", fingerprint: fp(title: "A"))]

        let actions = SyncPlanner.plan(
            local: [local(id, externalID: "E", title: "A")],
            remote: [remote("E", title: "A", priority: 1)],
            snapshot: snapshot
        )

        #expect(actions == [.updateRemote(localID: id, externalID: "E")])
    }

    @Test
    func remoteEditWithPriorityResetPullsRemoteThenResetsPriority() {
        let id = UUID()
        let snapshot = [id: SyncSnapshotEntry(reminderExternalID: "E", fingerprint: fp(title: "旧"))]
        let reminder = remote("E", title: "新", modified: Date(timeIntervalSince1970: 3_000), priority: 9)

        let actions = SyncPlanner.plan(
            local: [local(id, externalID: "E", title: "旧", updated: Date(timeIntervalSince1970: 1_000))],
            remote: [reminder],
            snapshot: snapshot
        )

        #expect(actions == [
            .updateLocal(localID: id, remote: reminder),
            .updateRemote(localID: id, externalID: "E"),
        ])
    }

    @Test
    func lostSnapshotWithMatchingExternalIDAndDifferentContentUsesLWW() {
        let id = UUID()
        let reminder = remote("E", title: "リモート", modified: Date(timeIntervalSince1970: 5_000))

        let actions = SyncPlanner.plan(
            local: [local(id, externalID: "E", title: "ローカル", updated: Date(timeIntervalSince1970: 1_000))],
            remote: [reminder],
            snapshot: [:]
        )

        #expect(actions == [.updateLocal(localID: id, remote: reminder)])
    }
}
