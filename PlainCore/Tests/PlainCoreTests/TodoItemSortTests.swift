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
func sortByPriorityWhenSameDueDate() {
    let due = date(2026, 4, 17)
    let items = [
        TodoItem(title: "A", priority: .low, dueDate: due),
        TodoItem(title: "B", priority: .high, dueDate: due),
        TodoItem(title: "C", priority: .medium, dueDate: due),
    ]

    let sortedTitles = items.sorted(by: TodoItemSort.compareActive).map(\.title)
    #expect(sortedTitles == ["B", "C", "A"])
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
