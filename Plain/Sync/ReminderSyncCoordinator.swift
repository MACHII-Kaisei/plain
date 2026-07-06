import EventKit
import Foundation
import SwiftData

@MainActor
final class ReminderSyncCoordinator {
    private let engine: ReminderSyncEngine
    private let store: ReminderStoring
    private var observers: [NSObjectProtocol] = []
    private var timer: Timer?
    private var debounceTask: Task<Void, Never>?
    private var isSyncing = false
    private var needsSyncAfterCurrent = false
    private var wasEnabled = ReminderSyncSettings.isEnabled

    init(container: ModelContainer) {
        let store = EventKitReminderStore()
        self.store = store
        self.engine = ReminderSyncEngine(
            context: container.mainContext,
            store: store,
            snapshots: SyncSnapshotStore(fileURL: SyncSnapshotStore.defaultURL())
        )
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        timer?.invalidate()
        debounceTask?.cancel()
    }

    func start() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.handleSettingsChange() }
        })
        observers.append(center.addObserver(forName: .EKEventStoreChanged, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.scheduleSync() }
        })
        observers.append(center.addObserver(forName: .plainDataDidChange, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.scheduleSync() }
        })
        observers.append(center.addObserver(forName: .plainReminderSyncNow, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in await self.requestAccessAndSync() }
        })

        if ReminderSyncSettings.isEnabled {
            startTimer()
            Task { await requestAccessAndSync() }
        }
    }

    private func handleSettingsChange() {
        let isEnabled = ReminderSyncSettings.isEnabled
        guard isEnabled != wasEnabled else { return }
        wasEnabled = isEnabled

        if isEnabled {
            startTimer()
            Task { await requestAccessAndSync() }
        } else {
            stopTimer()
            debounceTask?.cancel()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.scheduleSync() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func scheduleSync() {
        guard ReminderSyncSettings.isEnabled else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await self?.syncIfIdle()
        }
    }

    private func requestAccessAndSync() async {
        guard ReminderSyncSettings.isEnabled else { return }
        do {
            guard try await store.requestAccess() else {
                ReminderSyncSettings.recordError("リマインダーへのアクセスが許可されていません。")
                ReminderSyncSettings.isEnabled = false
                wasEnabled = false
                stopTimer()
                return
            }
            await syncIfIdle()
        } catch {
            ReminderSyncSettings.recordError(error.localizedDescription)
            print("[ReminderSync] access request failed: \(error)")
        }
    }

    private func syncIfIdle() async {
        guard ReminderSyncSettings.isEnabled else { return }
        guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
            ReminderSyncSettings.recordError("リマインダーへのアクセスが許可されていません。")
            return
        }

        if isSyncing {
            needsSyncAfterCurrent = true
            return
        }

        repeat {
            needsSyncAfterCurrent = false
            isSyncing = true
            await engine.syncNow()
            isSyncing = false
        } while needsSyncAfterCurrent && ReminderSyncSettings.isEnabled
    }
}
