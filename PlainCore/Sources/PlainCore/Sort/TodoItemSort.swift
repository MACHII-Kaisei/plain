import Foundation

public enum TodoItemSort {
    public static func compareActive(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        switch (lhs.dueDate, rhs.dueDate) {
        case let (l?, r?):
            if l != r { return l < r }
        case (nil, .some): return false
        case (.some, nil): return true
        case (nil, nil): break
        }
        if lhs.priority != rhs.priority {
            return lhs.priority.rawValue > rhs.priority.rawValue
        }
        return lhs.createdAt < rhs.createdAt
    }

    public static func compareCompleted(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        (lhs.completedAt ?? .distantPast) > (rhs.completedAt ?? .distantPast)
    }
}
