import Foundation

public enum TaskSortOrder: String, CaseIterable, Sendable {
    case dueDate
    case priority
    case createdAt
    case title

    public var label: String {
        switch self {
        case .dueDate:   "期日順"
        case .priority:  "優先度順"
        case .createdAt: "作成日順"
        case .title:     "タイトル順"
        }
    }
}

public enum TodoItemSort {
    /// 完了済みタスク用ソート（常に completedAt 降順）
    public static func compareCompleted(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        (lhs.completedAt ?? .distantPast) > (rhs.completedAt ?? .distantPast)
    }

    /// 未完了タスク用ソート（TaskSortOrder に応じて切り替え）
    public static func comparator(for order: TaskSortOrder) -> (TodoItem, TodoItem) -> Bool {
        switch order {
        case .dueDate:
            return compareDueDate
        case .priority:
            return comparePriority
        case .createdAt:
            return compareCreatedAt
        case .title:
            return compareTitle
        }
    }

    /// デフォルト: 期日昇順（nil最後）→ 優先度降順 → 作成日昇順
    public static func compareDueDate(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
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

    /// 優先度降順 → 期日昇順 → 作成日昇順
    public static func comparePriority(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority.rawValue > rhs.priority.rawValue
        }
        switch (lhs.dueDate, rhs.dueDate) {
        case let (l?, r?):
            if l != r { return l < r }
        case (nil, .some): return false
        case (.some, nil): return true
        case (nil, nil): break
        }
        return lhs.createdAt < rhs.createdAt
    }

    /// 作成日降順
    public static func compareCreatedAt(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        lhs.createdAt > rhs.createdAt
    }

    /// タイトル昇順（ロケール対応）
    public static func compareTitle(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        lhs.title.localizedCompare(rhs.title) == .orderedAscending
    }

    /// 後方互換: 既存コードで使われている compareActive を維持
    public static func compareActive(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        compareDueDate(lhs, rhs)
    }
}
