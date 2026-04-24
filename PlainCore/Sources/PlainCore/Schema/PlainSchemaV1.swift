import Foundation
import SwiftData

public enum PlainSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static let models: [any PersistentModel.Type] = [TodoItem.self]

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

        public init(title: String,
                    priority: Priority = .medium,
                    dueDate: Date? = nil,
                    notes: String? = nil,
                    urlString: String? = nil) {
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
        }
    }
}
