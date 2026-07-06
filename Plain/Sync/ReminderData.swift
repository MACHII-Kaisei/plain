import Foundation

struct ReminderData: Equatable {
    var externalID: String?
    var title: String
    var notes: String?
    var url: URL?
    var priority: Int
    var dueDate: Date?
    var hasDueTime: Bool
    var isCompleted: Bool
    var completedAt: Date?
    var lastModified: Date?
}
