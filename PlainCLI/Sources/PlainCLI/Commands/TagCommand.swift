import ArgumentParser
import Foundation
import SwiftData
import PlainCore

struct TagCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tag",
        abstract: "タグを管理",
        subcommands: [
            TagListCommand.self,
            TagCreateCommand.self,
            TagDeleteCommand.self,
        ]
    )
}

struct TagListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "タグ一覧を表示"
    )

    func run() throws {
        let container = try ContainerProvider.shared()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.createdAt)])
        let tags = try context.fetch(descriptor)

        if tags.isEmpty {
            print("  タグはありません")
            return
        }

        print("  色  タグ名            使用数")
        for tag in tags {
            let color = TagColor.from(index: tag.colorIndex)
            let colorName = "\(color)".padding(toLength: 6, withPad: " ", startingAt: 0)
            let name = tag.name.padding(toLength: 16, withPad: " ", startingAt: 0)
            let count = tag.items.count
            print("  \(colorName) \(name) \(count)件")
        }
    }
}

struct TagCreateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "タグを作成"
    )

    @Argument(help: "タグ名")
    var name: String

    @Option(name: .shortAndLong, help: "色インデックス (0-11)")
    var color: Int = 5

    func run() throws {
        let container = try ContainerProvider.shared()
        let context = ModelContext(container)

        let colorIndex = max(0, min(color, 11))
        let tag = Tag(name: name, colorIndex: colorIndex)
        context.insert(tag)
        try context.save()

        print("✓ タグ作成: \(name) (色: \(colorIndex))")
    }
}

struct TagDeleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "タグを削除"
    )

    @Argument(help: "タグ名")
    var name: String

    func run() throws {
        let container = try ContainerProvider.shared()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Tag>()
        let tags = try context.fetch(descriptor)

        guard let tag = tags.first(where: { $0.name == name }) else {
            print("✗ タグ「\(name)」が見つかりません")
            throw ExitCode.failure
        }

        context.delete(tag)
        try context.save()

        print("✓ タグ削除: \(name)")
        WidgetReloader.reload()
    }
}
