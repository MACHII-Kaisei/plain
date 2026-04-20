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

    @Flag(name: .long, help: "通知を無効化")
    var noNotify: Bool = false

    @Flag(name: .long, help: "通知を有効化")
    var notify: Bool = false

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
                // 日付だけ変更し、時刻は既存を維持
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
            // 時刻だけ変更
            item.dueDate = DateParser.applyTime(at, to: existingDue)
        }

        if let priority, let pri = PriorityParser.parse(priority) {
            item.priority = pri
        }
        if let note { item.notes = note.isEmpty ? nil : note }
        if let url { item.urlString = url.isEmpty ? nil : url }
        if noNotify { item.notificationEnabled = false }
        if notify { item.notificationEnabled = true }

        item.updatedAt = Date()
        try context.save()

        print("✓ 更新: \(item.title) (\(OutputFormatter.shortID(item.id)))")
        WidgetReloader.reload()
    }
}
