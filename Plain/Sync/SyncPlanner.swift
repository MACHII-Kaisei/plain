import Foundation

struct LocalItemState: Equatable {
    var id: UUID
    var externalID: String?
    var fingerprint: String
    var updatedAt: Date
    var isCompleted: Bool
}

enum SyncAction: Equatable, CustomStringConvertible {
    case createRemote(localID: UUID)
    case updateRemote(localID: UUID, externalID: String)
    case deleteRemote(externalID: String)
    case createLocal(remote: ReminderData)
    case updateLocal(localID: UUID, remote: ReminderData)
    case deleteLocal(localID: UUID)

    var description: String {
        switch self {
        case .createRemote(let localID):
            "createRemote(\(localID.uuidString))"
        case .updateRemote(let localID, let externalID):
            "updateRemote(\(localID.uuidString), \(externalID))"
        case .deleteRemote(let externalID):
            "deleteRemote(\(externalID))"
        case .createLocal(let remote):
            "createLocal(\(remote.externalID ?? "-"))"
        case .updateLocal(let localID, let remote):
            "updateLocal(\(localID.uuidString), \(remote.externalID ?? "-"))"
        case .deleteLocal(let localID):
            "deleteLocal(\(localID.uuidString))"
        }
    }
}

enum SyncPlanner {
    static func plan(local: [LocalItemState],
                     remote: [ReminderData],
                     snapshot: [UUID: SyncSnapshotEntry]) -> [SyncAction] {
        var actions: [SyncAction] = []
        let localByID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        var remoteByExternalID: [String: ReminderData] = [:]
        for reminder in remote {
            guard let externalID = reminder.externalID else { continue }
            remoteByExternalID[externalID] = reminder
        }

        var handledLocalIDs = Set<UUID>()
        var handledExternalIDs = Set<String>()

        for (localID, entry) in snapshot.sorted(by: { $0.key.uuidString < $1.key.uuidString }) {
            let localItem = localByID[localID]
            let remoteItem = remoteByExternalID[entry.reminderExternalID]
            handledLocalIDs.insert(localID)
            handledExternalIDs.insert(entry.reminderExternalID)

            switch (localItem, remoteItem) {
            case (nil, nil):
                continue
            case (nil, .some):
                actions.append(.deleteRemote(externalID: entry.reminderExternalID))
            case (.some(let localItem), nil):
                actions.append(.deleteLocal(localID: localItem.id))
            case (.some(let localItem), .some(let remoteItem)):
                actions.append(contentsOf: resolvePair(
                    local: localItem,
                    remote: remoteItem,
                    snapshotFingerprint: entry.fingerprint
                ))
            }
        }

        for localItem in local.sorted(by: { $0.id.uuidString < $1.id.uuidString })
        where !handledLocalIDs.contains(localItem.id) {
            if let externalID = localItem.externalID,
               let remoteItem = remoteByExternalID[externalID] {
                handledExternalIDs.insert(externalID)
                actions.append(contentsOf: resolvePair(
                    local: localItem,
                    remote: remoteItem,
                    snapshotFingerprint: nil
                ))
            } else if !localItem.isCompleted {
                actions.append(.createRemote(localID: localItem.id))
            }
        }

        for remoteItem in remote.sorted(by: { ($0.externalID ?? "") < ($1.externalID ?? "") }) {
            guard let externalID = remoteItem.externalID,
                  !handledExternalIDs.contains(externalID) else { continue }
            actions.append(.createLocal(remote: remoteItem))
        }

        return actions
    }

    private static func resolvePair(local: LocalItemState,
                                    remote: ReminderData,
                                    snapshotFingerprint: String?) -> [SyncAction] {
        guard let externalID = remote.externalID else { return [] }

        let remoteFingerprint = ReminderMapper.fingerprint(of: remote)
        let needsPriorityReset = ReminderMapper.shouldResetRemotePriority(remote)
        guard local.fingerprint != remoteFingerprint else {
            return needsPriorityReset ? [.updateRemote(localID: local.id, externalID: externalID)] : []
        }

        let localChanged = snapshotFingerprint.map { local.fingerprint != $0 } ?? true
        let remoteChanged = snapshotFingerprint.map { remoteFingerprint != $0 } ?? true

        let action: SyncAction
        switch (localChanged, remoteChanged) {
        case (true, false):
            action = .updateRemote(localID: local.id, externalID: externalID)
        case (false, true):
            action = .updateLocal(localID: local.id, remote: remote)
        default:
            let remoteModified = remote.lastModified ?? .distantPast
            action = local.updatedAt >= remoteModified
                ? .updateRemote(localID: local.id, externalID: externalID)
                : .updateLocal(localID: local.id, remote: remote)
        }

        guard needsPriorityReset else { return [action] }
        switch action {
        case .updateRemote:
            return [action]
        default:
            return [action, .updateRemote(localID: local.id, externalID: externalID)]
        }
    }
}
