import ArgumentParser
import Foundation
import SwiftData
import PlainCore

struct AddCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "タスクを追加"
    )

    @Argument(help: "タスクのタイトル")
    var title: String

    @Option(name: .shortAndLong, help: "期日: today, tomorrow, YYYY-MM-DD, MM-DD, +Nd")
    var due: String?

    @Option(name: [.customShort("t"), .long], help: "時刻: HH:mm（デフォルト 09:00）")
    var at: String?

    @Option(name: .shortAndLong, help: "優先度: high(h), medium(m), low(l)")
    var priority: String?

    @Option(name: .shortAndLong, help: "メモ")
    var note: String?

    @Option(name: .shortAndLong, help: "参照URL")
    var url: String?

    @Option(name: .long, help: "タグ名（複数指定可）")
    var tag: [String] = []

    @Flag(name: .long, help: "通知を無効化")
    var noNotify: Bool = false

    func run() throws {
        let container = try ContainerProvider.shared()
        let context = ModelContext(container)

        let dueDate = DateParser.parse(due: due, at: at)
        let pri = priority.flatMap { PriorityParser.parse($0) } ?? .medium

        let item = TodoItem(
            title: title,
            priority: pri,
            dueDate: dueDate,
            notes: note,
            urlString: url,
            notificationEnabled: !noNotify,
            hasDueTime: at != nil
        )

        // Resolve tags
        if !tag.isEmpty {
            let tagDescriptor = FetchDescriptor<Tag>()
            let allTags = (try? context.fetch(tagDescriptor)) ?? []
            for tagName in tag {
                if let existing = allTags.first(where: { $0.name == tagName }) {
                    item.tags.append(existing)
                } else {
                    let newTag = Tag(name: tagName, colorIndex: 5)
                    context.insert(newTag)
                    item.tags.append(newTag)
                }
            }
        }

        context.insert(item)
        try context.save()

        let id = OutputFormatter.shortID(item.id)
        print("✓ 追加: \(title) (\(id))")
        if let dueDate {
            print("  期日: \(OutputFormatter.formatDate(dueDate)) | 優先度: \(PriorityParser.label(pri))")
        } else {
            print("  優先度: \(PriorityParser.label(pri))")
        }
        if !tag.isEmpty {
            print("  タグ: \(tag.joined(separator: ", "))")
        }

        WidgetReloader.reload()
    }
}
