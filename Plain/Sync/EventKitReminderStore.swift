import EventKit
import Foundation

@MainActor
final class EventKitReminderStore: ReminderStoring {
    private let eventStore = EKEventStore()
    private var plainCalendar: EKCalendar?

    func requestAccess() async throws -> Bool {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess:
            return true
        case .denied, .restricted, .writeOnly:
            return false
        case .notDetermined:
            return try await eventStore.requestFullAccessToReminders()
        @unknown default:
            return false
        }
    }

    func ensurePlainList() throws {
        if let calendar = try findPlainCalendar() {
            plainCalendar = calendar
            return
        }

        let calendar = EKCalendar(for: .reminder, eventStore: eventStore)
        calendar.title = ReminderSyncSettings.listName

        guard let source = eventStore.defaultCalendarForNewReminders()?.source
            ?? eventStore.sources.first(where: { $0.sourceType == .calDAV })
            ?? eventStore.sources.first(where: { $0.sourceType == .local }) else {
            throw ReminderStoreError.listUnavailable
        }

        calendar.source = source
        try eventStore.saveCalendar(calendar, commit: true)
        UserDefaults.standard.set(calendar.calendarIdentifier, forKey: ReminderSyncSettings.calendarIDKey)
        plainCalendar = calendar
    }

    func fetchAll() async throws -> [ReminderData] {
        guard let calendar = plainCalendar else { throw ReminderStoreError.listUnavailable }
        let predicate = eventStore.predicateForReminders(in: [calendar])
        let reminders: [EKReminder] = await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { result in
                continuation.resume(returning: result ?? [])
            }
        }
        return reminders.map(Self.data(from:))
    }

    @discardableResult
    func create(_ data: ReminderData) throws -> String {
        guard let calendar = plainCalendar else { throw ReminderStoreError.listUnavailable }
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = calendar
        Self.apply(data, to: reminder)
        try eventStore.save(reminder, commit: true)
        return reminder.calendarItemExternalIdentifier
    }

    func update(_ data: ReminderData, externalID: String) throws {
        guard let reminder = findReminder(externalID: externalID) else {
            throw ReminderStoreError.reminderNotFound(externalID)
        }
        Self.apply(data, to: reminder)
        try eventStore.save(reminder, commit: true)
    }

    func delete(externalID: String) throws {
        guard let reminder = findReminder(externalID: externalID) else { return }
        try eventStore.remove(reminder, commit: true)
    }

    private func findPlainCalendar() throws -> EKCalendar? {
        let calendars = eventStore.calendars(for: .reminder)
        if let calendarID = UserDefaults.standard.string(forKey: ReminderSyncSettings.calendarIDKey) {
            guard let calendar = calendars.first(where: { $0.calendarIdentifier == calendarID }) else {
                throw ReminderStoreError.listUnavailable
            }
            return calendar
        }
        return calendars.first { $0.title == ReminderSyncSettings.listName }
    }

    private func findReminder(externalID: String) -> EKReminder? {
        eventStore.calendarItems(withExternalIdentifier: externalID)
            .compactMap { $0 as? EKReminder }
            .first
    }

    static func data(from reminder: EKReminder) -> ReminderData {
        let due = dateAndTimeFlag(from: reminder.dueDateComponents)
        return ReminderData(
            externalID: reminder.calendarItemExternalIdentifier,
            title: reminder.title ?? "",
            notes: reminder.notes,
            url: reminder.url,
            priority: reminder.priority,
            dueDate: due.date,
            hasDueTime: due.hasTime,
            isCompleted: reminder.isCompleted,
            completedAt: reminder.completionDate,
            lastModified: reminder.lastModifiedDate
        )
    }

    static func apply(_ data: ReminderData, to reminder: EKReminder) {
        reminder.title = data.title
        reminder.notes = data.notes
        reminder.url = data.url
        reminder.priority = data.priority
        reminder.isCompleted = data.isCompleted
        if data.isCompleted {
            reminder.completionDate = data.completedAt ?? Date()
        } else {
            reminder.completionDate = nil
        }

        if let dueDate = data.dueDate {
            let components: Set<Calendar.Component> = data.hasDueTime
                ? [.year, .month, .day, .hour, .minute]
                : [.year, .month, .day]
            reminder.dueDateComponents = Calendar.current.dateComponents(components, from: dueDate)
            reminder.alarms = data.hasDueTime && !data.isCompleted ? [EKAlarm(absoluteDate: dueDate)] : nil
        } else {
            reminder.dueDateComponents = nil
            reminder.alarms = nil
        }
    }

    private static func dateAndTimeFlag(from components: DateComponents?) -> (date: Date?, hasTime: Bool) {
        guard let components else { return (nil, false) }
        let hasTime = components.hour != nil || components.minute != nil || components.second != nil
        return (Calendar.current.date(from: components), hasTime)
    }
}
