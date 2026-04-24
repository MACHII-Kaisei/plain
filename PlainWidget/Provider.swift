import WidgetKit
import SwiftData
import PlainCore
import Foundation

struct TodayEntry: TimelineEntry {
    let date: Date
    let todayItems: [TodoItem.Snapshot]
    let upcomingItems: [TodoItem.Snapshot]
}

extension TodoItem {
    struct Snapshot: Identifiable, Hashable {
        let id: UUID
        let title: String
        let priority: Priority
        let dueDate: Date?
        let isCompleted: Bool
        let hasDueTime: Bool
    }

    var snapshot: Snapshot {
        .init(
            id: id,
            title: title,
            priority: priority,
            dueDate: dueDate,
            isCompleted: isCompleted,
            hasDueTime: hasDueTime
        )
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), todayItems: sampleItems(3), upcomingItems: sampleItems(2))
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(load(now: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date()
        let entry = load(now: now)
        let nextMidnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0),
            matchingPolicy: .nextTime
        )!
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    private func load(now: Date) -> TodayEntry {
        guard let container = try? SharedContainer.makeSharedContainer() else {
            return TodayEntry(date: now, todayItems: [], upcomingItems: [])
        }
        let ctx = ModelContext(container)
        let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { !$0.isCompleted })
        let all = (try? ctx.fetch(descriptor)) ?? []
        let today = all
            .filter {
                let section = TaskClassifier.classify(item: $0, now: now)
                return section == .today || section == .overdue
            }
            .sorted(by: TodoItemSort.compareActive)
            .prefix(5)
            .map(\.snapshot)
        let tomorrowStart = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: now)!
        )
        let upcoming = all
            .filter { item in
                guard let due = item.dueDate else { return false }
                return due >= tomorrowStart
            }
            .sorted { a, b in
                guard let da = a.dueDate, let db = b.dueDate else { return false }
                return da < db
            }
            .prefix(5)
            .map(\.snapshot)
        return TodayEntry(date: now, todayItems: Array(today), upcomingItems: Array(upcoming))
    }

    private func sampleItems(_ count: Int) -> [TodoItem.Snapshot] {
        (0..<count).map {
            TodoItem.Snapshot(
                id: UUID(),
                title: "サンプル\($0 + 1)",
                priority: .medium,
                dueDate: Date(),
                isCompleted: false,
                hasDueTime: false
            )
        }
    }
}
