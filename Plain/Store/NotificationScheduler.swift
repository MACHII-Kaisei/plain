import Foundation
import UserNotifications
import PlainCore

public protocol UNUserNotificationCenterProtocol {
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers: [String])
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
}

extension UNUserNotificationCenter: UNUserNotificationCenterProtocol {}

public final class NotificationScheduler {
    private let center: UNUserNotificationCenterProtocol

    public init(center: UNUserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.center = center
    }

    public func requestAuthorizationIfNeeded() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// `leadMinutes` 分前に通知をスケジュールする。
    /// デフォルト値は UserDefaults の "notificationLeadMinutes"（未設定時は 0 = ちょうど）。
    public func schedule(
        for item: TodoItem,
        leadMinutes: Int = UserDefaults.standard.integer(forKey: "notificationLeadMinutes")
    ) async {
        guard item.notificationEnabled else {
            center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
            return
        }
        guard let due = item.dueDate else { return }

        let notifyAt = due.addingTimeInterval(-Double(leadMinutes) * 60)

        guard notifyAt > Date() else {
            center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
            return
        }

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: notifyAt
        )

        let content = UNMutableNotificationContent()
        content.title = item.title
        if let notes = item.notes, !notes.isEmpty {
            content.body = notes
        }
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    public func cancel(for itemID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [itemID.uuidString])
    }
}
