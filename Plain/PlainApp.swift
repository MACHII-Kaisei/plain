import SwiftUI
import SwiftData
import WidgetKit
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
}

@main
struct PlainApp: App {
    let container: ModelContainer
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    init() {
        do {
            // UITest 実行中はインメモリコンテナを使用（App Group が使えない場合の対策）
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                container = try SharedContainer.makeInMemoryContainer()
            } else {
                container = try SharedContainer.makeSharedContainer()
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
                        case .newTask:
                            NotificationCenter.default.post(name: .plainNewTask, object: nil)
                        case .openTask(let id):
                            NotificationCenter.default.post(name: .plainOpenTask, object: id)
                        case .reload:
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    }
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
