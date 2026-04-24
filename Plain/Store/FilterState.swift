import Foundation
import PlainCore

@Observable
public class FilterState {
    public var priorities: Set<Priority> = []
    public var tagIDs: Set<UUID> = []
    public var dueDateFilter: DueDateFilter? = nil
    public var sortOrder: TaskSortOrder {
        didSet {
            UserDefaults.standard.set(sortOrder.rawValue, forKey: "sortOrder")
        }
    }

    public enum DueDateFilter: String, CaseIterable {
        case today
        case thisWeek
        case overdue
        case noDueDate

        public var label: String {
            switch self {
            case .today:     "今日"
            case .thisWeek:  "今週"
            case .overdue:   "期限切れ"
            case .noDueDate: "期日なし"
            }
        }
    }

    public init() {
        let saved = UserDefaults.standard.string(forKey: "sortOrder") ?? ""
        self.sortOrder = TaskSortOrder(rawValue: saved) ?? .dueDate
    }

    public var hasActiveFilters: Bool {
        !priorities.isEmpty || !tagIDs.isEmpty || dueDateFilter != nil
    }

    public func reset() {
        priorities = []
        tagIDs = []
        dueDateFilter = nil
    }

    public func apply(to items: [TodoItem], now: Date = Date()) -> [TodoItem] {
        var result = items

        // Priority filter
        if !priorities.isEmpty {
            result = result.filter { priorities.contains($0.priority) }
        }

        // Tag filter (OR: any of the selected tags)
        if !tagIDs.isEmpty {
            result = result.filter { item in
                item.tags.contains(where: { tagIDs.contains($0.id) })
            }
        }

        // Due date filter
        if let dueDateFilter {
            let cal = Calendar.current
            let todayStart = cal.startOfDay(for: now)
            switch dueDateFilter {
            case .today:
                let tomorrowStart = cal.date(byAdding: .day, value: 1, to: todayStart)!
                result = result.filter { item in
                    guard let due = item.dueDate else { return false }
                    let dueDay = cal.startOfDay(for: due)
                    return dueDay >= todayStart && dueDay < tomorrowStart
                }
            case .thisWeek:
                let weekLater = cal.date(byAdding: .day, value: 7, to: todayStart)!
                result = result.filter { item in
                    guard let due = item.dueDate else { return false }
                    return due >= todayStart && due < weekLater
                }
            case .overdue:
                result = result.filter { item in
                    guard let due = item.dueDate else { return false }
                    return cal.startOfDay(for: due) < todayStart
                }
            case .noDueDate:
                result = result.filter { $0.dueDate == nil }
            }
        }

        return result
    }
}
