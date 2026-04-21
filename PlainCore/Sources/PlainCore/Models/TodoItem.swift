import Foundation
import SwiftData

@Model
public final class TodoItem {
    public var id: UUID
    public var title: String
    public var priority: Priority
    public var dueDate: Date?
    public var isCompleted: Bool
    public var completedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var notes: String?
    public var urlString: String?
    public var notificationEnabled: Bool = true
    public var tags: [Tag] = []
    public var hasDueTime: Bool = false

    public init(title: String,
                priority: Priority = .medium,
                dueDate: Date? = nil,
                notes: String? = nil,
                urlString: String? = nil,
                notificationEnabled: Bool = true,
                hasDueTime: Bool = false) {
        self.id = UUID()
        self.title = title
        self.priority = priority
        self.dueDate = dueDate
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.notes = notes
        self.urlString = urlString
        self.notificationEnabled = notificationEnabled
        self.tags = []
        self.hasDueTime = hasDueTime
    }
}
