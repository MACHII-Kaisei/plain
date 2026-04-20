import SwiftUI
import AppKit
import PlainCore

struct TaskRowView: View {
    let item: TodoItem
    let onToggle: () -> Void
    let onEdit: () -> Void

    private var priorityColor: Color {
        switch item.priority {
        case .high: .red
        case .medium: .yellow
        case .low: .blue
        }
    }

    private static let dueDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日"
        return f
    }()

    private static func formatDue(_ date: Date) -> String {
        dueDateFormatter.string(from: date)
    }

    private var trimmedNotes: String? {
        guard let notes = item.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty else { return nil }
        return notes
    }

    private var trimmedURLString: String? {
        guard let urlString = item.urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !urlString.isEmpty else { return nil }
        return urlString
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(item.isCompleted ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
            }
            .accessibilityLabel(item.isCompleted ? "完了済み" : "未完了")
            .accessibilityIdentifier("toggle-\(item.id.uuidString)")
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                if let notes = trimmedNotes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let due = item.dueDate {
                Text(Self.formatDue(due))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let urlString = trimmedURLString {
                Button {
                    guard let url = URL(string: urlString) else { return }
                    NSWorkspace.shared.open(url)
                } label: {
                    Image(systemName: "link")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("URL を開く")
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("編集")

            Circle().fill(priorityColor).frame(width: 6, height: 6)
                .accessibilityLabel("優先度")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
