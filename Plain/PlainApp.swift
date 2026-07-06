import SwiftUI
import SwiftData
import WidgetKit
import AppKit
import PlainCore
import Sparkle

extension Notification.Name {
    static let plainNewTask = Notification.Name("plainNewTask")
    static let plainOpenTask = Notification.Name("plainOpenTask")
    static let plainToggleComplete = Notification.Name("plainToggleComplete")
    static let plainEditSelected = Notification.Name("plainEditSelected")
    static let plainDuplicateSelected = Notification.Name("plainDuplicateSelected")
    static let plainDeleteSelected = Notification.Name("plainDeleteSelected")
    static let plainSaveError = Notification.Name("plainSaveError")
    static let plainDataDidChange = Notification.Name("plainDataDidChange")
    static let plainReminderSyncNow = Notification.Name("plainReminderSyncNow")
}

@main
struct PlainApp: App {
    let container: ModelContainer
    @State private var syncCoordinator: ReminderSyncCoordinator?
    @State private var widgetActionCoordinator: WidgetActionCoordinator?
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    init() {
        do {
            // UITest 実行中はインメモリコンテナを使用（App Group が使えない場合の対策）
            let isRunningUITests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            if isRunningUITests {
                container = try SharedContainer.makeInMemoryContainer()
            } else {
                container = try SharedContainer.makeSharedContainer()
                // ウィジェットが書き残したペンディング操作を先に DB へ反映してから
                // スナップショットを書き出す（逆順だと完了操作が巻き戻って見える）
                WidgetActionStore().applyPendingActions(context: ModelContext(container))
                try? SharedWidgetSnapshotStore.write(from: container)
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            fatalError("Failed to init SharedContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TaskListView()
                .onOpenURL { url in
                    if let action = URLRouter.parse(url) {
                        switch action {
                        case .open:
                            NSApp.activate(ignoringOtherApps: true)
                        case .newTask:
                            NotificationCenter.default.post(name: .plainNewTask, object: nil)
                        case .openTask(let id):
                            NotificationCenter.default.post(name: .plainOpenTask, object: id)
                        case .reload:
                            WidgetCenter.shared.reloadAllTimelines()
                        case .sync:
                            NotificationCenter.default.post(name: .plainReminderSyncNow, object: nil)
                        }
                    }
                }
                .task {
                    guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
                          syncCoordinator == nil else { return }
                    let coordinator = ReminderSyncCoordinator(container: container)
                    coordinator.start()
                    syncCoordinator = coordinator
                }
                .task {
                    guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
                          widgetActionCoordinator == nil else { return }
                    let coordinator = WidgetActionCoordinator(container: container)
                    coordinator.start()
                    widgetActionCoordinator = coordinator
                }
        }
        .modelContainer(container)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("アップデートを確認…") {
                    updaterController.checkForUpdates(nil)
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("新規タスク") {
                    NotificationCenter.default.post(name: .plainNewTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandMenu("タスク") {
                Button("選択中を完了") {
                    NotificationCenter.default.post(name: .plainToggleComplete, object: nil)
                }
                .keyboardShortcut(.return, modifiers: .command)
                Button("選択中を編集") {
                    NotificationCenter.default.post(name: .plainEditSelected, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)
                Button("選択中を複製") {
                    NotificationCenter.default.post(name: .plainDuplicateSelected, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
                Button("選択中を削除") {
                    NotificationCenter.default.post(name: .plainDeleteSelected, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }
}
