import WidgetKit
import SwiftData
import PlainCore
import Foundation

struct TodayEntry: TimelineEntry {
    let date: Date
    let todoItems: [TodoItem.Snapshot]
}

extension TodoItem {
    struct TagSnapshot: Identifiable, Hashable {
        let id: UUID
        let name: String
        let colorIndex: Int
    }

    struct Snapshot: Identifiable, Hashable {
        let id: UUID
        let title: String
        let notes: String?
        let dueDate: Date?
        let isCompleted: Bool
        let hasDueTime: Bool
        let tags: [TagSnapshot]
    }

    var snapshot: Snapshot {
        .init(
            id: id,
            title: title,
            notes: notes,
            dueDate: dueDate,
            isCompleted: isCompleted,
            hasDueTime: hasDueTime,
            tags: tags
                .sorted { $0.createdAt < $1.createdAt }
                .map { TagSnapshot(id: $0.id, name: $0.name, colorIndex: $0.colorIndex) }
        )
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), todoItems: sampleItems(5))
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(load(now: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date()
        let entry = load(now: now)
        let timeline = Timeline(entries: [entry], policy: .after(nextReloadDate(after: now)))
        completion(timeline)
    }

    private func load(now: Date) -> TodayEntry {
        guard let container = try? SharedContainer.makeSharedContainer() else {
            return TodayEntry(date: now, todoItems: [])
        }
        let ctx = ModelContext(container)
        let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { !$0.isCompleted })
        let all = (try? ctx.fetch(descriptor)) ?? []
        let todoItems = all
            .sorted(by: TodoItemSort.compareActive)
            .map(\.snapshot)
        return TodayEntry(date: now, todoItems: todoItems)
    }

    private func nextReloadDate(after now: Date) -> Date {
        let calendar = Calendar.current
        let nextMidnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0),
            matchingPolicy: .nextTime
        )!
        let nextHour = calendar.nextDate(
            after: now,
            matching: DateComponents(minute: 0, second: 0),
            matchingPolicy: .nextTime
        )!
        return min(nextMidnight, nextHour)
    }

    private func sampleItems(_ count: Int) -> [TodoItem.Snapshot] {
        (0..<count).map {
            TodoItem.Snapshot(
                id: UUID(),
                title: "サンプル\($0 + 1)",
                notes: $0 == 0 ? "メモのプレビュー" : nil,
                dueDate: Date(),
                isCompleted: false,
                hasDueTime: false,
                tags: [
                    TodoItem.TagSnapshot(id: UUID(), name: "仕事", colorIndex: TagColor.blue.rawValue)
                ]
            )
        }
    }
}
