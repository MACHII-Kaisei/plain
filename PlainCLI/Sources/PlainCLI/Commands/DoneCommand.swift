import ArgumentParser
import Foundation
import SwiftData
import PlainCore

struct DoneCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "done",
        abstract: "タスクを完了にする"
    )

    @Argument(help: "タスクID（短縮IDまたはフルUUID）")
    var id: String

    func run() throws {
        let container = try ContainerProvider.shared()
        let context = ModelContext(container)
        let item = try IDResolver.resolve(id, in: context)

        item.isCompleted = true
        item.completedAt = Date()
        item.updatedAt = Date()
        try context.save()

        print("✓ 完了: \(item.title) (\(OutputFormatter.shortID(item.id)))")
        WidgetReloader.reload()
    }
}

struct UndoneCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "undone",
        abstract: "タスクの完了を取り消す"
    )

    @Argument(help: "タスクID（短縮IDまたはフルUUID）")
    var id: String

    func run() throws {
        let container = try ContainerProvider.shared()
        let context = ModelContext(container)
        let item = try IDResolver.resolve(id, in: context)

        item.isCompleted = false
        item.completedAt = nil
        item.updatedAt = Date()
        try context.save()

        print("✓ 取消: \(item.title) (\(OutputFormatter.shortID(item.id)))")
        WidgetReloader.reload()
    }
}
