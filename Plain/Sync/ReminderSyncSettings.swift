import Foundation

enum ReminderSyncSettings {
    static let enabledKey = "reminderSyncEnabled"
    static let listNameKey = "reminderSyncListName"
    static let lastSuccessAtKey = "reminderSyncLastSuccessAt"
    static let lastErrorKey = "reminderSyncLastError"
    static let calendarIDKey = "plainReminderCalendarID"

    static let defaultListName = "Plain"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var listName: String {
        let value = UserDefaults.standard.string(forKey: listNameKey) ?? defaultListName
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultListName : trimmed
    }

    static func recordSuccess(at date: Date = Date()) {
        UserDefaults.standard.set(date, forKey: lastSuccessAtKey)
        UserDefaults.standard.removeObject(forKey: lastErrorKey)
    }

    static func recordError(_ message: String) {
        UserDefaults.standard.set(message, forKey: lastErrorKey)
    }

    static func resetCalendarConnection() {
        UserDefaults.standard.removeObject(forKey: calendarIDKey)
    }
}
