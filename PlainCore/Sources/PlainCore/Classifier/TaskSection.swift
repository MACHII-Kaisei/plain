import Foundation

public enum TaskSection: String, CaseIterable, Sendable {
    case today
    case tomorrow
    case upcoming
    case overdue
    case someday
    case completed
}

public enum TaskClassifier {
    public static func classify(item: TodoItem, now: Date = Date()) -> TaskSection {
        if item.isCompleted { return .completed }
        guard let due = item.dueDate else { return .someday }
        let today = now.startOfDay
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let dueDay = due.startOfDay
        if dueDay < today { return .overdue }
        if dueDay == today { return .today }
        if dueDay == tomorrow { return .tomorrow }
        return .upcoming
    }
}
