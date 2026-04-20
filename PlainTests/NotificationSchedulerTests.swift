import Foundation
import Testing
import UserNotifications
import PlainCore
@testable import Plain

class MockCenter: UNUserNotificationCenterProtocol, @unchecked Sendable {
    var addedRequests: [UNNotificationRequest] = []
    var removedIdentifiers: [String] = []

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers: [String]) {
        removedIdentifiers = withIdentifiers
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        true
    }
}

struct NotificationSchedulerTests {

    // MARK: - 既存テスト（dueDate を 2099 年に更新）

    @Test
    func schedulesNotificationForItemWithDueDate() async throws {
        let mock = MockCenter()
        let scheduler = NotificationScheduler(center: mock)
        let dueDate = Calendar.current.date(
            from: DateComponents(year: 2099, month: 1, day: 1, hour: 14, minute: 30)
        )!
        let item = TodoItem(title: "X", dueDate: dueDate)

        await scheduler.schedule(for: item, leadMinutes: 0)

        #expect(mock.addedRequests.count == 1)
        let request = try #require(mock.addedRequests.first)
        #expect(request.identifier == item.id.uuidString)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.dateComponents.year == 2099)
        #expect(trigger.dateComponents.month == 1)
        #expect(trigger.dateComponents.day == 1)
        #expect(trigger.dateComponents.hour == 14)
        #expect(trigger.dateComponents.minute == 30)
    }

    @Test
    func cancelRemovesPendingRequest() {
        let mock = MockCenter()
        let scheduler = NotificationScheduler(center: mock)
        let someUUID = UUID()

        scheduler.cancel(for: someUUID)

        #expect(mock.removedIdentifiers == [someUUID.uuidString])
    }

    // MARK: - 新規テスト

    @Test
    func schedulesNotificationAtLeadTimeBeforeDue() async throws {
        let mock = MockCenter()
        let scheduler = NotificationScheduler(center: mock)
        // due: 2099-01-01 14:30, leadMinutes: 30 → notify at 14:00
        let dueDate = Calendar.current.date(
            from: DateComponents(year: 2099, month: 1, day: 1, hour: 14, minute: 30)
        )!
        let item = TodoItem(title: "Lead test", dueDate: dueDate)

        await scheduler.schedule(for: item, leadMinutes: 30)

        #expect(mock.addedRequests.count == 1)
        let trigger = try #require(mock.addedRequests.first?.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.dateComponents.hour == 14)
        #expect(trigger.dateComponents.minute == 0)
    }

    @Test
    func skipsAndCancelsWhenNotifyTimeIsInPast() async {
        let mock = MockCenter()
        let scheduler = NotificationScheduler(center: mock)
        // due: 過去の日付 → notifyAt も過去 → add されない
        let pastDue = Calendar.current.date(
            from: DateComponents(year: 2020, month: 1, day: 1, hour: 10, minute: 0)
        )!
        let item = TodoItem(title: "Past item", dueDate: pastDue)

        await scheduler.schedule(for: item, leadMinutes: 0)

        #expect(mock.addedRequests.isEmpty)
        #expect(mock.removedIdentifiers == [item.id.uuidString])
    }

    @Test
    func zeroLeadMinutesSchedulesAtExactDueTime() async throws {
        let mock = MockCenter()
        let scheduler = NotificationScheduler(center: mock)
        let dueDate = Calendar.current.date(
            from: DateComponents(year: 2099, month: 6, day: 15, hour: 9, minute: 0)
        )!
        let item = TodoItem(title: "Zero lead", dueDate: dueDate)

        await scheduler.schedule(for: item, leadMinutes: 0)

        #expect(mock.addedRequests.count == 1)
        let trigger = try #require(mock.addedRequests.first?.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.dateComponents.hour == 9)
        #expect(trigger.dateComponents.minute == 0)
    }

    @Test
    func skipsAndCancelsWhenNotificationDisabled() async {
        let mock = MockCenter()
        let scheduler = NotificationScheduler(center: mock)
        let dueDate = Calendar.current.date(
            from: DateComponents(year: 2099, month: 1, day: 1, hour: 14, minute: 0)
        )!
        let item = TodoItem(title: "Disabled", dueDate: dueDate, notificationEnabled: false)

        await scheduler.schedule(for: item, leadMinutes: 0)

        #expect(mock.addedRequests.isEmpty)
        #expect(mock.removedIdentifiers == [item.id.uuidString])
    }
}
