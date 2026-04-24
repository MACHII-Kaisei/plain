import ArgumentParser
import Foundation
import SwiftData
import PlainCore

struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "タスク一覧を表示"
    )

    @Argument(help: "フィルタ: today, tomorrow, overdue, done（省略で未完了すべて）")
    var filter: String?

    @Option(name: .long, help: "タグで絞り込み（複数指定可）")
    var tag: [String] = []

    @Option(name: .shortAndLong, help: "優先度で絞り込み: high(h), medium(m), low(l)")
    var priority: String?

    @Option(name: .shortAndLong, help: "並び替え: dueDate, priority, createdAt, title")
    var sort: String?

    @Flag(name: .shortAndLong, help: "JSON形式で出力")
    var json: Bool = false

    func run() throws {
        let container = try ContainerProvider.shared()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TodoItem>()
        let all = try context.fetch(descriptor)

        let filtered: [TodoItem]
        let filterSection: TaskSection?

        switch filter?.lowercased() {
        case "today":
            filterSection = .today
            filtered = all.filter { TaskClassifier.classify(item: $0) == .today }
        case "tomorrow":
            filterSection = .tomorrow
            filtered = all.filter { TaskClassifier.classify(item: $0) == .tomorrow }
        case "overdue":
            filterSection = .overdue
            filtered = all.filter { TaskClassifier.classify(item: $0) == .overdue }
        case "done":
            filterSection = .completed
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            filtered = all.filter {
                $0.isCompleted && ($0.completedAt ?? .distantPast) > sevenDaysAgo
            }.sorted(by: TodoItemSort.compareCompleted)
        case nil:
            filterSection = nil
            filtered = all.filter { !$0.isCompleted }
        default:
            throw ValidationError("不明なフィルタ: \(filter ?? ""). today, tomorrow, overdue, done が使えます")
        }

        if json {
            printJSON(filtered)
        } else if filterSection != nil {
            let sorted = filterSection == .completed
                ? filtered
                : applySortAndFilter(filtered)
            printTable(sorted)
        } else {
            let sorted = applySortAndFilter(filtered)
            printGroupedOrTable(sorted)
        }
    }

    private func applySortAndFilter(_ items: [TodoItem]) -> [TodoItem] {
        var result = items

        // Filter by priority
        if let priority, let pri = PriorityParser.parse(priority) {
            result = result.filter { $0.priority == pri }
        }

        // Filter by tag
        if !tag.isEmpty {
            result = result.filter { item in
                item.tags.contains(where: { tag.contains($0.name) })
            }
        }

        // Sort
        if let sort, let sortOrder = TaskSortOrder(rawValue: sort) {
            result = result.sorted(by: TodoItemSort.comparator(for: sortOrder))
        } else {
            result = result.sorted(by: TodoItemSort.compareActive)
        }

        return result
    }

    private func printGroupedOrTable(_ items: [TodoItem]) {
        if filter == nil && tag.isEmpty && priority == nil {
            printGrouped(items)
        } else {
            printTable(items)
        }
    }

    private func printTable(_ items: [TodoItem]) {
        if items.isEmpty {
            print("  タスクはありません")
            return
        }
        print("  ID       優先度  期日              タイトル")
        for item in items {
            let id = OutputFormatter.shortID(item.id)
            let pri = PriorityParser.label(item.priority)
            let due = OutputFormatter.formatDate(item.dueDate)
            let title = item.title
            let tagSuffix = item.tags.isEmpty ? "" : " [\(item.tags.map(\.name).joined(separator: ", "))]"
            print("  \(id)   \(pri)     \(due.padding(toLength: 12, withPad: " ", startingAt: 0))    \(title)\(tagSuffix)")
        }
    }

    private func printGrouped(_ items: [TodoItem]) {
        let sectionOrder: [TaskSection] = [.overdue, .today, .tomorrow, .upcoming, .someday]
        var grouped: [TaskSection: [TodoItem]] = [:]

        for item in items {
            let section = TaskClassifier.classify(item: item)
            grouped[section, default: []].append(item)
        }

        var hasOutput = false
        for section in sectionOrder {
            guard let sectionItems = grouped[section], !sectionItems.isEmpty else { continue }
            if hasOutput { print() }
            print("\(OutputFormatter.sectionLabel(section)):")
            let sorted = sectionItems.sorted(by: TodoItemSort.compareActive)
            printTable(sorted)
            hasOutput = true
        }

        if !hasOutput {
            print("  タスクはありません")
        }
    }

    private func printJSON(_ items: [TodoItem]) {
        var result: [[String: Any]] = []
        for item in items {
            var dict: [String: Any] = [
                "id": item.id.uuidString,
                "shortId": OutputFormatter.shortID(item.id),
                "title": item.title,
                "priority": priorityString(item.priority),
                "isCompleted": item.isCompleted,
                "section": TaskClassifier.classify(item: item).rawValue,
            ]
            if let due = item.dueDate {
                dict["dueDate"] = ISO8601DateFormatter().string(from: due)
            }
            if let notes = item.notes {
                dict["notes"] = notes
            }
            if let url = item.urlString {
                dict["url"] = url
            }
            result.append(dict)
        }
        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }

    private func priorityString(_ p: Priority) -> String {
        switch p {
        case .high: return "high"
        case .medium: return "medium"
        case .low: return "low"
        }
    }
}
