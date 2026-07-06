import Foundation
import Testing
import PlainCore
@testable import Plain

struct ReminderMapperTests {
    @Test
    func priorityIsAlwaysNoneForReminders() {
        #expect(ReminderMapper.reminderPriority(from: .high) == 0)
        #expect(ReminderMapper.reminderPriority(from: .medium) == 0)
        #expect(ReminderMapper.reminderPriority(from: .low) == 0)
    }

    @Test @MainActor
    func dataFromItemMapsAllFields() {
        let due = Date(timeIntervalSince1970: 1_780_000_000)
        let item = TodoItem(
            title: "買い物",
            priority: .high,
            dueDate: due,
            notes: "牛乳",
            urlString: "https://example.com",
            hasDueTime: true
        )
        item.reminderExternalID = "EXT-1"

        let data = ReminderMapper.data(from: item)

        #expect(data.title == "買い物")
        #expect(data.priority == 0)
        #expect(data.dueDate == due)
        #expect(data.hasDueTime)
        #expect(data.notes == "牛乳")
        #expect(data.url == URL(string: "https://example.com"))
        #expect(data.externalID == "EXT-1")
        #expect(!data.isCompleted)
    }

    @Test @MainActor
    func applyDataOverwritesItem() {
        let completedAt = Date(timeIntervalSince1970: 1_780_100_000)
        let item = TodoItem(title: "古い", priority: .high)
        let data = ReminderData(
            externalID: "EXT-2",
            title: "新しい",
            notes: "メモ",
            url: URL(string: "https://x.test"),
            priority: 9,
            dueDate: Date(timeIntervalSince1970: 1_780_000_000),
            hasDueTime: false,
            isCompleted: true,
            completedAt: completedAt,
            lastModified: nil
        )

        ReminderMapper.apply(data, to: item, now: Date(timeIntervalSince1970: 1_780_200_000))

        #expect(item.title == "新しい")
        #expect(item.priority == .high)
        #expect(item.notes == "メモ")
        #expect(item.urlString == "https://x.test")
        #expect(!item.hasDueTime)
        #expect(item.isCompleted)
        #expect(item.completedAt == completedAt)
        #expect(item.reminderExternalID == "EXT-2")
    }

    @Test @MainActor
    func fingerprintMatchesForEquivalentLocalAndRemote() {
        let due = Date(timeIntervalSince1970: 1_780_000_000)
        let item = TodoItem(title: "A", priority: .medium, dueDate: due, hasDueTime: true)
        let remote = ReminderData(
            externalID: "E",
            title: "A",
            notes: nil,
            url: nil,
            priority: 9,
            dueDate: due,
            hasDueTime: true,
            isCompleted: false,
            completedAt: nil,
            lastModified: Date()
        )

        #expect(ReminderMapper.fingerprint(of: ReminderMapper.data(from: item)) == ReminderMapper.fingerprint(of: remote))
    }

    @Test
    func priorityResetDetection() {
        var data = ReminderData(
            externalID: "E",
            title: "A",
            notes: nil,
            url: nil,
            priority: 0,
            dueDate: nil,
            hasDueTime: false,
            isCompleted: false,
            completedAt: nil,
            lastModified: nil
        )
        #expect(!ReminderMapper.shouldResetRemotePriority(data))

        data.priority = 1
        #expect(ReminderMapper.shouldResetRemotePriority(data))
    }

    @Test
    func fingerprintIgnoresSecondsWhenTimed() throws {
        let calendar = Calendar(identifier: .gregorian)
        let base = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 12,
            hour: 10,
            minute: 30,
            second: 10
        )))
        let a = ReminderData(
            externalID: nil,
            title: "A",
            notes: nil,
            url: nil,
            priority: 5,
            dueDate: base,
            hasDueTime: true,
            isCompleted: false,
            completedAt: nil,
            lastModified: nil
        )
        var b = a
        b.dueDate = base.addingTimeInterval(30)

        #expect(ReminderMapper.fingerprint(of: a, calendar: calendar) == ReminderMapper.fingerprint(of: b, calendar: calendar))
    }
}
