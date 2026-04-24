import Foundation
import SwiftData

public enum PlainSchemaV2: VersionedSchema {
    public static let versionIdentifier = Schema.Version(2, 0, 0)
    public static let models: [any PersistentModel.Type] = [TodoItem.self, Tag.self]

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
            self.tags = []
            self.hasDueTime = hasDueTime
        }
    }

    @Model
    public final class Tag {
        public var id: UUID
        public var name: String
        public var colorIndex: Int
        public var createdAt: Date

        @Relationship(inverse: \TodoItem.tags)
        public var items: [TodoItem]

        public init(name: String, colorIndex: Int) {
            self.id = UUID()
            self.name = name
            self.colorIndex = colorIndex
            self.createdAt = Date()
            self.items = []
        }
    }
}
