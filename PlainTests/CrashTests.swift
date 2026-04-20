import Foundation
import Testing
import SwiftData
import PlainCore
@testable import Plain

struct CrashTests {

    // Task 8.2-1: 100件投入してもクラッシュしない
    @Test @MainActor
    func hundredTasksDoNotCrash() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)
        let context = container.mainContext

        for i in 1...100 {
            store.add(title: "タスク \(i)", priority: [.low, .medium, .high][i % 3], dueDate: i % 3 == 0 ? Date() : nil)
        }

        let items = try context.fetch(FetchDescriptor<TodoItem>())
        #expect(items.count == 100)
    }

    // Task 8.2-2: タイトル500文字でも保存できる
    @Test @MainActor
    func fiveHundredCharTitleSavesCorrectly() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)
        let context = container.mainContext

        let longTitle = String(repeating: "あ", count: 500)
        let item = store.add(title: longTitle)

        let fetched = try context.fetch(FetchDescriptor<TodoItem>())
        #expect(fetched.first?.title == longTitle)
        #expect(item.title.count == 500)
    }

    // Task 8.2-3: dueDate なし・あり混在でも正しくソートされる
    @Test @MainActor
    func mixedDueDateSortIsCorrect() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        store.add(title: "期日なし", priority: .high, dueDate: nil)
        store.add(title: "明日", priority: .low, dueDate: tomorrow)
        store.add(title: "昨日", priority: .medium, dueDate: yesterday)
        store.add(title: "今日", priority: .high, dueDate: today)

        let context = container.mainContext
        let all = try context.fetch(FetchDescriptor<TodoItem>())
        let sorted = all.sorted(by: TodoItemSort.compareActive)

        // 昨日 → 今日 → 明日 → 期日なし の順
        #expect(sorted[0].title == "昨日")
        #expect(sorted[1].title == "今日")
        #expect(sorted[2].title == "明日")
        #expect(sorted[3].title == "期日なし")
    }

    // Task 8.2-4: 100件に対して toggleComplete を全件実行してもクラッシュしない
    @Test @MainActor
    func toggleCompleteHundredTimesDoNotCrash() throws {
        let container = try SharedContainer.makeInMemoryContainer()
        let store = TodoStore(container: container)
        let context = container.mainContext

        for i in 1...100 {
            store.add(title: "タスク \(i)")
        }

        let items = try context.fetch(FetchDescriptor<TodoItem>())
        for item in items {
            store.toggleComplete(item)
        }

        let completed = try context.fetch(FetchDescriptor<TodoItem>(predicate: #Predicate { $0.isCompleted }))
        #expect(completed.count == 100)
    }
}
