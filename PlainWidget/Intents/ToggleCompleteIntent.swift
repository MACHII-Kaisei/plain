import AppIntents
import SwiftData
import WidgetKit
import PlainCore
import Foundation

struct ToggleCompleteIntent: AppIntent {
    static var title: LocalizedStringResource = "完了切替"
    static var description = IntentDescription("タスクの完了状態を切り替えます。")

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        let container = try SharedContainer.makeSharedContainer()
        let context = ModelContext(container)
        guard let uuid = UUID(uuidString: taskID) else { return .result() }
        let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == uuid })
        if let item = try context.fetch(descriptor).first {
            item.isCompleted.toggle()
            item.completedAt = item.isCompleted ? Date() : nil
            item.updatedAt = Date()
            try context.save()
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
