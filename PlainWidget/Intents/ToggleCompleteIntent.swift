import AppIntents
import SwiftData
import WidgetKit
import PlainCore
import Foundation
import OSLog

struct ToggleCompleteIntent: AppIntent {
    static var title: LocalizedStringResource = "完了切替"
    static var description = IntentDescription("タスクの完了状態を切り替えます。")
    static var openAppWhenRun = false

    private static let logger = Logger(subsystem: "app.plain.Plain", category: "ToggleCompleteIntent")

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        Self.logger.info("Widget toggle started: \(taskID, privacy: .public)")
        defer {
            WidgetCenter.shared.reloadTimelines(ofKind: "TodayWidget")
            WidgetCenter.shared.reloadAllTimelines()
        }

        guard let uuid = UUID(uuidString: taskID) else {
            Self.logger.error("Invalid task ID for widget toggle: \(taskID, privacy: .public)")
            return .result()
        }

        do {
            try toggleDirectly(uuid)
        } catch {
            // adhoc 署名ビルドではウィジェット拡張から Group Container の DB を
            // 開けない（サンドボックスに拒否される）ため、ペンディング操作として
            // 書き残し、本体アプリ側で DB に反映する。
            Self.logger.error("Direct toggle failed, using pending action fallback: \(String(describing: error), privacy: .public)")
            enqueueFallbackAction(for: uuid)
        }
        return .result()
    }

    /// Group Container の DB を直接更新する（正規署名ビルド用の従来経路）。
    @MainActor
    private func toggleDirectly(_ uuid: UUID) throws {
        let container = try SharedContainer.makeSharedContainer()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == uuid })
        guard let item = try context.fetch(descriptor).first else {
            Self.logger.error("Task not found for widget toggle: \(taskID, privacy: .public)")
            return
        }
        item.isCompleted.toggle()
        item.completedAt = item.isCompleted ? Date() : nil
        item.updatedAt = Date()
        try context.save()
        Self.logger.info("Widget toggle saved directly: \(taskID, privacy: .public)")
        do {
            try SharedWidgetSnapshotStore.write(from: container)
        } catch {
            Self.logger.error("Failed to refresh widget snapshot after toggle: \(String(describing: error), privacy: .public)")
        }
    }

    /// ペンディング操作を書き残し、表示用スナップショットを楽観的に更新する。
    private func enqueueFallbackAction(for uuid: UUID) {
        let currentState = (try? SharedWidgetSnapshotStore.load())?
            .todoItems.first(where: { $0.id == uuid })?.isCompleted ?? false
        let desired = !currentState
        let action = WidgetToggleAction(id: UUID(), taskID: uuid, desiredCompleted: desired, createdAt: Date())

        do {
            try WidgetActionStore().enqueue(action)
            Self.logger.info("Enqueued pending widget action: \(uuid.uuidString, privacy: .public) desired=\(desired)")
        } catch {
            // 楽観的更新は enqueue 成功時のみ（永続化経路のない見かけ状態を作らないため）
            Self.logger.error("Failed to enqueue pending widget action: \(String(describing: error), privacy: .public)")
            return
        }

        do {
            try SharedWidgetSnapshotStore.applyLocalCompletion(taskID: uuid, isCompleted: desired)
        } catch {
            Self.logger.error("Failed optimistic snapshot update: \(String(describing: error), privacy: .public)")
        }
    }
}
