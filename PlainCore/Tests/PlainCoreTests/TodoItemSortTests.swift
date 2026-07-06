import Foundation
import Testing
import PlainCore

@Test
func sortByDueDateAscendingWithNilLast() {
    let items = [
        TodoItem(title: "A", dueDate: nil),
        TodoItem(title: "B", dueDate: date(2026, 4, 18)),
        TodoItem(title: "C", dueDate: date(2026, 4, 17)),
    ]

    let sortedTitles = items.sorted(by: TodoItemSort.compareActive).map(\.title)
    #expect(sortedTitles == ["C", "B", "A"])
}

@Test
func sortByCreatedAtWhenSameDueDate() {
    let due = date(2026, 4, 17)
    let older = TodoItem(title: "A", dueDate: due)
    older.createdAt = date(2026, 4, 15)
    let newer = TodoItem(title: "B", dueDate: due)
    newer.createdAt = date(2026, 4, 16)

    let sortedTitles = [newer, older].sorted(by: TodoItemSort.compareActive).map(\.title)
    #expect(sortedTitles == ["A", "B"])
}

@Test
func sortCompletedByCompletedAtDescending() {
    let completedEarlier = TodoItem(title: "A")
    completedEarlier.completedAt = date(2026, 4, 17)

    let completedLater = TodoItem(title: "B")
    completedLater.completedAt = date(2026, 4, 18)

    let sortedTitles = [completedEarlier, completedLater]
        .sorted(by: TodoItemSort.compareCompleted)
        .map(\.title)

    #expect(sortedTitles == ["B", "A"])
}

private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
}
