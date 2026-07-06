import Foundation
import PlainCore

enum ReminderMapper {
    static let noneReminderPriority = 0

    static func reminderPriority(from _: Priority) -> Int {
        noneReminderPriority
    }

    static func shouldResetRemotePriority(_ data: ReminderData) -> Bool {
        data.priority != noneReminderPriority
    }

    @MainActor
    static func data(from item: TodoItem) -> ReminderData {
        ReminderData(
            externalID: item.reminderExternalID,
            title: item.title,
            notes: item.notes,
            url: item.urlString.flatMap(URL.init(string:)),
            priority: reminderPriority(from: item.priority),
            dueDate: item.dueDate,
            hasDueTime: item.hasDueTime,
            isCompleted: item.isCompleted,
            completedAt: item.completedAt,
            lastModified: item.updatedAt
        )
    }

    @MainActor
    static func apply(_ data: ReminderData, to item: TodoItem, now: Date = Date()) {
        item.title = data.title
        item.notes = data.notes
        item.urlString = data.url?.absoluteString
        item.dueDate = data.dueDate
        item.hasDueTime = data.hasDueTime
        item.isCompleted = data.isCompleted
        item.completedAt = data.isCompleted ? (data.completedAt ?? now) : nil
        item.reminderExternalID = data.externalID
        item.updatedAt = now
    }

    static func fingerprint(of data: ReminderData, calendar: Calendar = .current) -> String {
        [
            data.title,
            data.notes ?? "",
            data.url?.absoluteString ?? "",
            normalizedDueDateKey(data.dueDate, hasDueTime: data.hasDueTime, calendar: calendar),
            data.hasDueTime ? "time" : "date",
            data.isCompleted ? "completed" : "active",
        ].joined(separator: "\u{1f}")
    }

    private static func normalizedDueDateKey(_ date: Date?, hasDueTime: Bool, calendar: Calendar) -> String {
        guard let date else { return "-" }
        let components: DateComponents
        if hasDueTime {
            components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            return [
                components.year,
                components.month,
                components.day,
                components.hour,
                components.minute,
            ].map { $0.map(String.init) ?? "-" }.joined(separator: ".")
        } else {
            components = calendar.dateComponents([.year, .month, .day], from: date)
            return [
                components.year,
                components.month,
                components.day,
            ].map { $0.map(String.init) ?? "-" }.joined(separator: ".")
        }
    }
}
