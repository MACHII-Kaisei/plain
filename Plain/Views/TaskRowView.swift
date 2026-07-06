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
        HStack(alignment: .center, spacing: 10) {
            if isBulkMode {
                Button(action: onBulkToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? Color(hex: 0x0058bc) : Color(hex: 0xc1c6d7))
                }
                .buttonStyle(.plain)
            }

            if !isBulkMode {
                Button(action: onToggle) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(item.isCompleted ? Color(hex: 0x0058bc) : Color(hex: 0xc1c6d7))
                }
                .accessibilityLabel(item.isCompleted ? "完了済み" : "未完了")
                .accessibilityIdentifier("toggle-\(item.id.uuidString)")
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .strikethrough(item.isCompleted)
                        .foregroundStyle(item.isCompleted ? Color(hex: 0x717786) : Color(hex: 0x181c23))
                        .lineLimit(1)
                        .layoutPriority(0)

                    if showTags && !item.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(item.tags, id: \.id) { tag in
                                tagChip(tag)
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(2)
                    }
                }

                HStack(spacing: 10) {
                    if let notes = trimmedNotes {
                        Text(notes)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0x717786))
                            .lineLimit(1)
                    }
                    if let due = item.dueDate {
                        Label(formatDue(due), systemImage: item.hasDueTime ? "clock" : "calendar")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: 0x717786))
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isBulkMode {
                if let urlString = trimmedURLString {
                    Button {
                        guard let url = URL(string: urlString) else { return }
                        NSWorkspace.shared.open(url)
                    } label: {
                        Image(systemName: "link")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(hex: 0x717786))
                    .accessibilityLabel("URL を開く")
                }

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(hex: 0x717786))
                .accessibilityLabel("編集")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: 0xecedf3), lineWidth: 1)
        }
        .contentShape(Rectangle())
    }

    private func tagChip(_ tag: Tag) -> some View {
        let color = TagColor.from(index: tag.colorIndex)
        return Text(tag.name)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color.foregroundColor)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.backgroundColor, in: Capsule())
    }
}

private extension Color {
    init(hex: Int) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255
        )
    }
}
