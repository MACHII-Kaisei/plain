import SwiftUI
import AppKit
import PlainCore

struct TaskRowView: View {
    let item: TodoItem
    let showNotes: Bool
    let showTags: Bool
    let isBulkMode: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onBulkToggle: () -> Void

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

    private static let dueDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日 HH:mm"
        return f
    }()

    private func formatDue(_ date: Date) -> String {
        if item.hasDueTime {
            return Self.dueDateTimeFormatter.string(from: date)
        }
        return Self.dueDateFormatter.string(from: date)
    }

    private var trimmedNotes: String? {
        guard showNotes,
              let notes = item.notes?.trimmingCharacters(in: .whitespacesAndNewlines),
              !notes.isEmpty else { return nil }
        return notes
    }

    private var trimmedURLString: String? {
        guard let urlString = item.urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !urlString.isEmpty else { return nil }
        return urlString
    }

    var body: some View {
        HStack(spacing: 12) {
            // Bulk selection checkbox
            if isBulkMode {
                Button(action: onBulkToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            // Completion toggle
            if !isBulkMode {
                Button(action: onToggle) {
                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                        .foregroundStyle(item.isCompleted ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
                }
                .accessibilityLabel(item.isCompleted ? "完了済み" : "未完了")
                .accessibilityIdentifier("toggle-\(item.id.uuidString)")
                .buttonStyle(.plain)
            }

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

                // Tag chips
                if showTags && !item.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.tags, id: \.id) { tag in
                            let color = TagColor.from(index: tag.colorIndex)
                            Text(tag.name)
                                .font(.caption2)
                                .foregroundStyle(color.foregroundColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(color.backgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()

            if let due = item.dueDate {
                Text(formatDue(due))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !isBulkMode {
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
            }

            Circle().fill(priorityColor).frame(width: 6, height: 6)
                .accessibilityLabel("優先度")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
