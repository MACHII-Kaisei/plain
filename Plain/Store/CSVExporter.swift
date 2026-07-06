import Foundation
import AppKit
import UniformTypeIdentifiers
import SwiftData
import PlainCore

@MainActor
enum CSVExporter {
    static func export(context: ModelContext) {
        let descriptor = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.createdAt)])
        guard let items = try? context.fetch(descriptor) else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "plain_tasks.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        var csv = "タイトル,期日,時刻,完了,タグ,メモ,URL,作成日\n"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ja_JP")
        timeFormatter.dateFormat = "HH:mm"

        let createdAtFormatter = DateFormatter()
        createdAtFormatter.locale = Locale(identifier: "ja_JP")
        createdAtFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        for item in items {
            let title = escapeCSV(item.title)
            let dueDate: String
            let dueTime: String
            if let due = item.dueDate {
                dueDate = dateFormatter.string(from: due)
                dueTime = item.hasDueTime ? timeFormatter.string(from: due) : ""
            } else {
                dueDate = ""
                dueTime = ""
            }

            let completed = item.isCompleted ? "完了" : "未完了"
            let tags = item.tags.map(\.name).joined(separator: "/")
            let notes = escapeCSV(item.notes ?? "")
            let urlString = escapeCSV(item.urlString ?? "")
            let createdAt = createdAtFormatter.string(from: item.createdAt)

            csv += "\(title),\(dueDate),\(dueTime),\(completed),\(escapeCSV(tags)),\(notes),\(urlString),\(createdAt)\n"
        }

        try? csv.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
