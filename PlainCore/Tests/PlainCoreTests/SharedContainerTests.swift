import Testing
import SwiftData
import PlainCore
import Foundation

@Test
func appGroupIdentifierIsExpected() {
    #expect(SharedContainer.appGroupIdentifier == "group.app.plain.Plain")
}

@Test
@MainActor
func inMemoryContainerCanInsertAndFetchTodoItem() throws {
    let container = try SharedContainer.makeInMemoryContainer()
    let context = ModelContext(container)

    context.insert(TodoItem(title: "テスト"))
    try context.save()

    let descriptor = FetchDescriptor<TodoItem>()
    let items = try context.fetch(descriptor)

    #expect(items.count == 1)
    #expect(items.first?.title == "テスト")
}
