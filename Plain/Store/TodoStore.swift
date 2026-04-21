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

    // MARK: - CRUD

    @discardableResult
    public func add(title: String,
                    priority: Priority = .medium,
                    dueDate: Date? = nil,
                    notes: String? = nil,
                    urlString: String? = nil,
                    notificationEnabled: Bool = true,
                    hasDueTime: Bool = false,
                    tags: [Tag] = []) -> TodoItem {
        let item = TodoItem(title: title,
                            priority: priority,
                            dueDate: dueDate,
                            notes: notes,
                            urlString: urlString,
                            notificationEnabled: notificationEnabled,
                            hasDueTime: hasDueTime)
        item.tags = tags
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
                       notificationEnabled: Bool? = nil,
                       hasDueTime: Bool? = nil,
                       tags: [Tag]? = nil) {
        if let title { item.title = title }
        if let priority { item.priority = priority }
        if let dueDate { item.dueDate = dueDate }
        if let notes { item.notes = notes }
        if let urlString { item.urlString = urlString }
        if let notificationEnabled { item.notificationEnabled = notificationEnabled }
        if let hasDueTime { item.hasDueTime = hasDueTime }
        if let tags { item.tags = tags }
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
                            notificationEnabled: item.notificationEnabled,
                            hasDueTime: item.hasDueTime)
        copy.tags = item.tags
        context.insert(copy)
        try? context.save()
        syncNotification(for: copy)
        WidgetCenter.shared.reloadAllTimelines()
        return copy
    }

    // MARK: - Batch operations

    public func batchToggleComplete(_ items: [TodoItem]) {
        for item in items {
            item.isCompleted.toggle()
            item.completedAt = item.isCompleted ? Date() : nil
            item.updatedAt = Date()
        }
        try? context.save()
        for item in items {
            syncNotification(for: item)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    public func batchDelete(_ items: [TodoItem]) {
        for item in items {
            scheduler.cancel(for: item.id)
            context.delete(item)
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    public func batchAddTag(_ tag: Tag, to items: [TodoItem]) {
        for item in items {
            if !item.tags.contains(where: { $0.id == tag.id }) {
                item.tags.append(tag)
            }
            item.updatedAt = Date()
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    public func batchRemoveTag(_ tag: Tag, from items: [TodoItem]) {
        for item in items {
            item.tags.removeAll(where: { $0.id == tag.id })
            item.updatedAt = Date()
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Tag CRUD

    @discardableResult
    public func addTag(name: String, colorIndex: Int) -> Tag {
        let tag = Tag(name: name, colorIndex: colorIndex)
        context.insert(tag)
        try? context.save()
        return tag
    }

    public func updateTag(_ tag: Tag, name: String? = nil, colorIndex: Int? = nil) {
        if let name { tag.name = name }
        if let colorIndex { tag.colorIndex = colorIndex }
        try? context.save()
    }

    public func deleteTag(_ tag: Tag) {
        context.delete(tag)
        try? context.save()
    }

    public func fetchAllTags() -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Data management

    public func deleteAllCompleted() -> Int {
        let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.isCompleted })
        let items = (try? context.fetch(descriptor)) ?? []
        let count = items.count
        for item in items {
            scheduler.cancel(for: item.id)
            context.delete(item)
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return count
    }
}
