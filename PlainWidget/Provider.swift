import WidgetKit
import SwiftData
import PlainCore
import Foundation

struct TodayEntry: TimelineEntry {
    let date: Date
    let todoItems: [WidgetTodoItemSnapshot]
    let message: String?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), todoItems: sampleItems(5), message: nil)
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
        do {
            let cache = try SharedWidgetSnapshotStore.load()
            return TodayEntry(date: now, todoItems: cache.todoItems, message: nil)
        } catch {
            let snapshotError = shortError(error)

            do {
                let container = try SharedContainer.makeSharedContainer()
                let ctx = ModelContext(container)
                let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { !$0.isCompleted })
                let all = (try? ctx.fetch(descriptor)) ?? []
                let todoItems = all
                    .sorted(by: TodoItemSort.compareActive)
                    .map { item in
                        WidgetTodoItemSnapshot(
                            id: item.id,
                            title: item.title,
                            notes: item.notes,
                            dueDate: item.dueDate,
                            isCompleted: item.isCompleted,
                            hasDueTime: item.hasDueTime,
                            tags: item.tags
                                .sorted { $0.createdAt < $1.createdAt }
                                .map { WidgetTagSnapshot(id: $0.id, name: $0.name, colorIndex: $0.colorIndex) }
                        )
                    }
                return TodayEntry(date: now, todoItems: todoItems, message: nil)
            } catch {
                return TodayEntry(
                    date: now,
                    todoItems: [],
                    message: "読込失敗 S:\(snapshotError) D:\(shortError(error))"
                )
            }
        }
    }

    private func shortError(_ error: Error) -> String {
        let nsError = error as NSError
        let code = "\(nsError.domain)#\(nsError.code)"
        let details = String(describing: error)
            .replacingOccurrences(of: "\n", with: " ")
            .prefix(80)
        return "\(code) \(details)"
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

    private func sampleItems(_ count: Int) -> [WidgetTodoItemSnapshot] {
        (0..<count).map {
            WidgetTodoItemSnapshot(
                id: UUID(),
                title: "サンプル\($0 + 1)",
                notes: $0 == 0 ? "メモのプレビュー" : nil,
                dueDate: Date(),
                isCompleted: false,
                hasDueTime: false,
                tags: [
                    WidgetTagSnapshot(id: UUID(), name: "仕事", colorIndex: TagColor.blue.rawValue)
                ]
            )
        }
    }
}
