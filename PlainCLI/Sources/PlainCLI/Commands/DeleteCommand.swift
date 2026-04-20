import ArgumentParser
import Foundation
import SwiftData
import PlainCore

struct DeleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "タスクを削除"
    )

    @Argument(help: "タスクID（短縮IDまたはフルUUID）")
    var id: String

    func run() throws {
        let container = try ContainerProvider.shared()
        let context = ModelContext(container)
        let item = try IDResolver.resolve(id, in: context)

        let title = item.title
        let shortID = OutputFormatter.shortID(item.id)
        context.delete(item)
        try context.save()

        print("✓ 削除: \(title) (\(shortID))")
        WidgetReloader.reload()
    }
}
