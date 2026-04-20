import Foundation
import SwiftData
import WidgetKit
import PlainCore

@MainActor
public final class TodoStore {
    public let container: ModelContainer
    public var context: ModelContext { container.mainContext }
    private let scheduler: NotificationScheduler

    public init(container: ModelContainer, scheduler: NotificationScheduler = NotificationScheduler()) {
        self.container = container
        self.scheduler = scheduler
    }

    private func notificationsEnabled() -> Bool {
        if UserDefaults.standard.object(forKey: "notificationsEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }

    private func syncNotification(for item: TodoItem) {
        guard notificationsEnabled(),
              item.notificationEnabled,
              item.dueDate != nil,
              !item.isCompleted else {
            scheduler.cancel(for: item.id)
            return
        }
        Task {
            await scheduler.schedule(for: item)
        }
    }

    @discardableResult
    public func add(title: String,
                    priority: Priority = .medium,
                    dueDate: Date? = nil,
                    notes: String? = nil,
                    urlString: String? = nil,
                    notificationEnabled: Bool = true) -> TodoItem {
        let item = TodoItem(title: title,
                            priority: priority,
                            dueDate: dueDate,
                            notes: notes,
                            urlString: urlString,
                            notificationEnabled: notificationEnabled)
        context.insert(item)
        try? context.save()
        syncNotification(for: item)
        WidgetCenter.shared.reloadAllTimelines()
        return item
    }

    public func update(_ item: TodoItem,
                       title: String? = nil,
                       priority: Priority? = nil,
                       dueDate: Date?? = nil,
                       notes: String?? = nil,
                       urlString: String?? = nil,
                       notificationEnabled: Bool? = nil) {
        if let title { item.title = title }
        if let priority { item.priority = priority }
        if let dueDate { item.dueDate = dueDate }
        if let notes { item.notes = notes }
        if let urlString { item.urlString = urlString }
        if let notificationEnabled { item.notificationEnabled = notificationEnabled }
        item.updatedAt = Date()
        try? context.save()
        syncNotification(for: item)
        WidgetCenter.shared.reloadAllTimelines()
    }

    public func toggleComplete(_ item: TodoItem) {
        item.isCompleted.toggle()
        item.completedAt = item.isCompleted ? Date() : nil
        item.updatedAt = Date()
        try? context.save()
        syncNotification(for: item)
        WidgetCenter.shared.reloadAllTimelines()
    }

    public func delete(_ item: TodoItem) {
        scheduler.cancel(for: item.id)
        context.delete(item)
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    @discardableResult
    public func duplicate(_ item: TodoItem) -> TodoItem {
        let copy = TodoItem(title: item.title + " (コピー)",
                            priority: item.priority,
                            dueDate: item.dueDate,
                            notes: item.notes,
                            urlString: item.urlString,
                            notificationEnabled: item.notificationEnabled)
        context.insert(copy)
        try? context.save()
        syncNotification(for: copy)
        WidgetCenter.shared.reloadAllTimelines()
        return copy
    }
}
