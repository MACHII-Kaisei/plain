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
        let container = try SharedContainer.makeSharedContainer()
        let context = ModelContext(container)
        guard let uuid = UUID(uuidString: taskID) else { return .result() }
        let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == uuid })
        if let item = try context.fetch(descriptor).first {
            item.isCompleted.toggle()
            item.completedAt = item.isCompleted ? Date() : nil
            item.updatedAt = Date()
            try context.save()
            Self.logger.info("Widget toggle saved: \(taskID, privacy: .public)")
            do {
                try SharedWidgetSnapshotStore.write(from: container)
                Self.logger.info("Widget snapshot refreshed after toggle: \(taskID, privacy: .public)")
            } catch {
                Self.logger.error("Failed to refresh widget snapshot after toggle: \(String(describing: error), privacy: .public)")
            }
        } else {
            Self.logger.error("Task not found for widget toggle: \(taskID, privacy: .public)")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "TodayWidget")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
