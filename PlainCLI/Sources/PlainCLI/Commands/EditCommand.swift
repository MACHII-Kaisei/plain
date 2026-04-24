import ArgumentParser
import Foundation
import SwiftData
import PlainCore

struct EditCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "タスクを編集"
    )

    @Argument(help: "タスクID（短縮IDまたはフルUUID）")
    var id: String

    @Option(name: .long, help: "タイトルを変更")
    var title: String?

    @Option(name: .shortAndLong, help: "期日を変更: today, tomorrow, YYYY-MM-DD, MM-DD, +Nd")
    var due: String?

    @Option(name: [.customShort("t"), .long], help: "時刻を変更: HH:mm")
    var at: String?

    @Flag(name: .long, help: "期日を解除")
    var noDue: Bool = false

    @Option(name: .shortAndLong, help: "優先度を変更: high(h), medium(m), low(l)")
    var priority: String?

    @Option(name: .shortAndLong, help: "メモを変更")
    var note: String?

    @Option(name: .shortAndLong, help: "URLを変更")
    var url: String?

    @Option(name: .long, help: "タグを追加（複数指定可）")
    var addTag: [String] = []

    @Option(name: .long, help: "タグを削除（複数指定可）")
    var removeTag: [String] = []

    func run() throws {
        let container = try ContainerProvider.shared()
        let context = ModelContext(container)
        let item = try IDResolver.resolve(id, in: context)

        if let title { item.title = title }

        if noDue {
            item.dueDate = nil
        } else if let due {
            if let at {
                item.dueDate = DateParser.parse(due: due, at: at)
            } else if let existingDue = item.dueDate {
                if let newDate = DateParser.parseDate(due) {
                    let cal = Calendar.current
                    let timeComps = cal.dateComponents([.hour, .minute], from: existingDue)
                    var dateComps = cal.dateComponents([.year, .month, .day], from: newDate)
                    dateComps.hour = timeComps.hour
                    dateComps.minute = timeComps.minute
                    item.dueDate = cal.date(from: dateComps)
                }
            } else {
                item.dueDate = DateParser.parse(due: due, at: at)
            }
        } else if let at, let existingDue = item.dueDate {
            item.dueDate = DateParser.applyTime(at, to: existingDue)
        }

        if let priority, let pri = PriorityParser.parse(priority) {
            item.priority = pri
        }
        if let note { item.notes = note.isEmpty ? nil : note }
        if let url { item.urlString = url.isEmpty ? nil : url }

        // Tag operations
        if !addTag.isEmpty || !removeTag.isEmpty {
            let tagDescriptor = FetchDescriptor<Tag>()
            let allTags = (try? context.fetch(tagDescriptor)) ?? []

            for tagName in addTag {
                if let existing = allTags.first(where: { $0.name == tagName }) {
                    if !item.tags.contains(where: { $0.id == existing.id }) {
                        item.tags.append(existing)
                    }
                } else {
                    let newTag = Tag(name: tagName, colorIndex: 5)
                    context.insert(newTag)
                    item.tags.append(newTag)
                }
            }

            for tagName in removeTag {
                item.tags.removeAll(where: { $0.name == tagName })
            }
        }

        item.updatedAt = Date()
        try context.save()

        print("✓ 更新: \(item.title) (\(OutputFormatter.shortID(item.id)))")
        if !item.tags.isEmpty {
            print("  タグ: \(item.tags.map(\.name).joined(separator: ", "))")
        }
        WidgetReloader.reload()
    }
}
