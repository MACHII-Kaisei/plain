import Foundation
import Testing
import SwiftData
import PlainCore

@Test
func todoItemDefaults() {
    let item = TodoItem(title: "タスクA")

    #expect(item.id is UUID)
    #expect(item.title == "タスクA")
    #expect(item.priority == .medium)
    #expect(item.dueDate == nil)
    #expect(item.isCompleted == false)
    #expect(item.completedAt == nil)
    #expect(abs(item.createdAt.timeIntervalSince(Date())) <= 5)
}

@Test
func todoItemDueDatePreservesTimeOfDay() throws {
    let components = DateComponents(year: 2026, month: 4, day: 17, hour: 10, minute: 30)
    let input = try #require(Calendar.current.date(from: components))
    let item = TodoItem(title: "X", priority: .high, dueDate: input)

    #expect(item.dueDate == input)
    #expect(item.priority == .high)
}

@Test
func todoItemStoresNotesAndURL() {
    let item = TodoItem(title: "Y",
                        notes: "メモ",
                        urlString: "https://example.com")
    #expect(item.notes == "メモ")
    #expect(item.urlString == "https://example.com")
}

@Test
func todoItemCompletedAtIsInitiallyNil() {
    let item = TodoItem(title: "Y")
    #expect(item.completedAt == nil)
}
