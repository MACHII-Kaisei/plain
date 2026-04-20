import Foundation
import Testing
import PlainCore

@Test
func classifyToday() {
    let now = makeDate(year: 2026, month: 4, day: 17, hour: 12)
    let item = TodoItem(title: "a", dueDate: makeDate(year: 2026, month: 4, day: 17, hour: 10))

    let section = TaskClassifier.classify(item: item, now: now)
    #expect(section == .today)
}

@Test
func classifyTomorrow() {
    let now = makeDate(year: 2026, month: 4, day: 17, hour: 12)
    let item = TodoItem(title: "a", dueDate: makeDate(year: 2026, month: 4, day: 18))

    let section = TaskClassifier.classify(item: item, now: now)
    #expect(section == .tomorrow)
}

@Test
func classifyUpcoming() {
    let now = makeDate(year: 2026, month: 4, day: 17, hour: 12)
    let item = TodoItem(title: "a", dueDate: makeDate(year: 2026, month: 4, day: 20))

    let section = TaskClassifier.classify(item: item, now: now)
    #expect(section == .upcoming)
}

@Test
func classifyOverdue() {
    let now = makeDate(year: 2026, month: 4, day: 17, hour: 12)
    let item = TodoItem(title: "a", dueDate: makeDate(year: 2026, month: 4, day: 15))

    let section = TaskClassifier.classify(item: item, now: now)
    #expect(section == .overdue)
}

@Test
func classifySomeday() {
    let now = makeDate(year: 2026, month: 4, day: 17, hour: 12)
    let item = TodoItem(title: "a", dueDate: nil)

    let section = TaskClassifier.classify(item: item, now: now)
    #expect(section == .someday)
}

@Test
func classifyCompleted() throws {
    let now = makeDate(year: 2026, month: 4, day: 17, hour: 12)
    let item = TodoItem(title: "a", dueDate: makeDate(year: 2026, month: 4, day: 17))
    item.isCompleted = true
    _ = try #require(item.dueDate)

    let section = TaskClassifier.classify(item: item, now: now)
    #expect(section == .completed)
}

private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0) -> Date {
    let c = DateComponents(year: year, month: month, day: day, hour: hour)
    return Calendar.current.date(from: c)!
}
