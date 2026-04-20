import SwiftUI
import WidgetKit
import AppIntents
import PlainCore

struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            widgetHeader(
                title: family == .systemLarge ? "今日" : "今日のタスク",
                count: entry.todayItems.count
            )
            .padding(.bottom, 16)

            taskList(entry.todayItems, maxCount: family == .systemLarge ? 5 : 3)

            if family == .systemLarge {
                widgetHeader(title: "今後", count: entry.upcomingItems.count)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                taskList(entry.upcomingItems, maxCount: 5)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .containerBackground(for: .widget) { Color.white }
    }

    // MARK: - Header

    private func widgetHeader(title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: 0x0058bc))
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: 0x181c23))
            Spacer()
            Text("\(count)件")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: 0x717786))
        }
    }

    // MARK: - Task list

    @ViewBuilder
    private func taskList(_ items: [TodoItem.Snapshot], maxCount: Int) -> some View {
        if items.isEmpty {
            Text("タスクなし")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0x717786))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.prefix(maxCount))) { item in
                    taskRow(item)
                }
            }
        }
    }

    // MARK: - Task row

    private func taskRow(_ item: TodoItem.Snapshot) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button(intent: ToggleCompleteIntent(taskID: item.id.uuidString)) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(
                        item.isCompleted
                            ? Color(hex: 0x0058bc)
                            : Color(hex: 0xc1c6d7)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "完了済み" : "未完了")

            VStack(alignment: .leading, spacing: 4) {
                Link(destination: URL(string: "plain://task/\(item.id.uuidString)")!) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            item.isCompleted
                                ? Color(hex: 0x717786)
                                : item.priority == .low
                                    ? Color(hex: 0x414755)
                                    : Color(hex: 0x181c23)
                        )
                        .strikethrough(item.isCompleted)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if let due = item.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundStyle(
                                    item.priority == .low
                                        ? Color(hex: 0x717786)
                                        : Color(hex: 0x414755)
                                )
                            Text(Self.timeFormatter.string(from: due))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(
                                    item.priority == .low
                                        ? Color(hex: 0x717786)
                                        : Color(hex: 0x414755)
                                )
                        }
                    }
                    priorityChip(item.priority)
                }
            }
        }
    }

    // MARK: - Priority chip

    private func priorityChip(_ priority: Priority) -> some View {
        Text(priority.chipLabel)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(priority.chipTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(priority.chipColor, in: Capsule())
    }
}

// MARK: - Priority extensions

private extension Priority {
    var chipLabel: String {
        switch self {
        case .high:   "高"
        case .medium: "中"
        case .low:    "低"
        }
    }

    var chipColor: Color {
        switch self {
        case .high:   Color(hex: 0xc64f00)
        case .medium: Color(hex: 0xa1befd)
        case .low:    Color(hex: 0xecedf9)
        }
    }

    var chipTextColor: Color {
        switch self {
        case .high:   Color(hex: 0xfffbff)
        case .medium: Color(hex: 0x2d4c83)
        case .low:    Color(hex: 0x414755)
        }
    }
}

// MARK: - Color hex init

private extension Color {
    init(hex: Int) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255
        )
    }
}
