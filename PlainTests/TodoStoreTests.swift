import Foundation
import Testing
import SwiftData
import PlainCore
@testable import Plain

struct TodoStoreTests {
    @Test @MainActor
    func addInsertsItemWithDefaults() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)
        let context = container.mainContext

        let item = store.add(title: "A")
        let items = try context.fetch(FetchDescriptor<TodoItem>())

        #expect(items.count == 1)
        #expect(item.title == "A")
        #expect(item.isCompleted == false)
        #expect(item.priority == .medium)
        #expect(item.dueDate == nil)
    }

    @Test @MainActor
    func addPreservesDueDateWithTime() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)
        let calendar = Calendar.current
        let input = calendar.date(from: DateComponents(year: 2026, month: 4, day: 17, hour: 10, minute: 30))!

        let item = store.add(title: "B", dueDate: input)
        let dueDate = try #require(item.dueDate)

        #expect(dueDate == input)
    }

    @Test @MainActor
    func addStoresNotesAndURL() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)

        let item = store.add(title: "E",
                             notes: "メモ内容",
                             urlString: "https://example.com")

        #expect(item.notes == "メモ内容")
        #expect(item.urlString == "https://example.com")
    }

    @Test @MainActor
    func updateChangesNotesAndURL() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)
        let item = store.add(title: "F")

        store.update(item, notes: Optional("メモ"), urlString: Optional("https://x.test"))

        #expect(item.notes == "メモ")
        #expect(item.urlString == "https://x.test")
    }

    @Test @MainActor
    func updateChangesTitleAndPriorityAndUpdatesTimestamp() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)
        let item = store.add(title: "old")
        let originalUpdatedAt = item.updatedAt

        Thread.sleep(forTimeInterval: 0.01)
        store.update(item, title: "new", priority: .high)

        #expect(item.title == "new")
        #expect(item.priority == .high)
        #expect(item.updatedAt > originalUpdatedAt)
    }

    @Test @MainActor
    func toggleCompleteSetsAndClearsCompletedAt() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)
        let item = store.add(title: "C")

        #expect(item.isCompleted == false)

        store.toggleComplete(item)
        #expect(item.isCompleted == true)
        #expect(item.completedAt != nil)

        store.toggleComplete(item)
        #expect(item.isCompleted == false)
        #expect(item.completedAt == nil)
    }

    @Test @MainActor
    func deleteRemovesItem() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)
        let context = container.mainContext
        let item = store.add(title: "D")

        let before = try context.fetch(FetchDescriptor<TodoItem>())
        #expect(before.count == 1)

        store.delete(item)

        let after = try context.fetch(FetchDescriptor<TodoItem>())
        #expect(after.count == 0)
    }

    @Test @MainActor
    func duplicateCreatesCopyWithSuffix() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)
        let context = container.mainContext
        let inputDate = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 17, hour: 9, minute: 0))!
        let item = store.add(title: "元", priority: .high, dueDate: inputDate)

        let copy = store.duplicate(item)
        let items = try context.fetch(FetchDescriptor<TodoItem>())

        #expect(copy.title == "元 (コピー)")
        #expect(copy.priority == .high)
        #expect(copy.dueDate == item.dueDate)
        #expect(items.count == 2)
    }
}
