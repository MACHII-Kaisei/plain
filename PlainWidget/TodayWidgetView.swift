import SwiftUI
import WidgetKit
import AppIntents
import PlainCore

struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    private var rowSlots: Int { family == .systemLarge ? 8 : 3 }
    private var rowHeight: CGFloat { family == .systemLarge ? 30 : 32 }
    private let rowSpacing: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            widgetHeader(title: "TODO", count: entry.todoItems.count)
            .padding(.bottom, 8)

            taskList(entry.todoItems, slots: rowSlots)

            Spacer(minLength: 0)
        }
        .padding(18)
        .widgetURL(URL(string: "plain://open")!)
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
    private func taskList(_ items: [TodoItem.Snapshot], slots: Int) -> some View {
        let visibleLimit = items.count > slots ? max(slots - 1, 0) : slots
        let visibleItems = Array(items.prefix(visibleLimit))
        let hiddenCount = max(items.count - visibleItems.count, 0)
        let fixedHeight = CGFloat(slots) * rowHeight + CGFloat(max(slots - 1, 0)) * rowSpacing

        if items.isEmpty {
            Text("タスクなし")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0x717786))
                .frame(maxWidth: .infinity, minHeight: fixedHeight, maxHeight: fixedHeight, alignment: .topLeading)
        } else {
            VStack(alignment: .leading, spacing: rowSpacing) {
                ForEach(visibleItems) { item in
                    taskRow(item)
                }
                if hiddenCount > 0 {
                    moreRow(count: hiddenCount)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: fixedHeight, maxHeight: fixedHeight, alignment: .topLeading)
            .clipped()
        }
    }

    // MARK: - Task row

    private func taskRow(_ item: TodoItem.Snapshot) -> some View {
        let isUrgent = isDueTodayOrOverdue(item)

        return HStack(alignment: .center, spacing: 9) {
            Button(intent: ToggleCompleteIntent(taskID: item.id.uuidString)) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(
                        item.isCompleted
                            ? Color(hex: 0x0058bc)
                            : isUrgent ? Color(hex: 0xd92d20) : Color(hex: 0xc1c6d7)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "完了済み" : "未完了")

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Link(destination: URL(string: "plain://task/\(item.id.uuidString)")!) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(
                                item.isCompleted
                                    ? Color(hex: 0x717786)
                                    : isUrgent
                                    ? Color(hex: 0xb42318)
                                    : Color(hex: 0x181c23)
                            )
                            .strikethrough(item.isCompleted)
                            .lineLimit(1)
                    }
                    .layoutPriority(0)

                    inlineMeta(item)
                        .layoutPriority(2)
                }

                if let notes = item.notes?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: 0x717786))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: rowHeight)
    }

    @ViewBuilder
    private func inlineMeta(_ item: TodoItem.Snapshot) -> some View {
        if item.dueDate != nil || !item.tags.isEmpty {
            HStack(spacing: 4) {
                ForEach(item.tags) { tag in
                    tagChip(tag)
                }
                if let due = item.dueDate {
                    dueBadge(item: item, due: due, now: entry.date)
                }
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private func tagChip(_ tag: TodoItem.TagSnapshot) -> some View {
        let color = TagColor.from(index: tag.colorIndex)
        return Text(tag.name)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color.foregroundColor)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.backgroundColor, in: Capsule())
    }

    private func dueBadge(item: TodoItem.Snapshot, due: Date, now: Date) -> some View {
        let state = dueState(due: due, hasDueTime: item.hasDueTime, now: now)
        return Text(state.label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(state.isUrgent ? Color(hex: 0xb42318) : Color(hex: 0x414755))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func moreRow(count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 12, weight: .medium))
            Text("他\(count)件")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Color(hex: 0x717786))
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: rowHeight)
    }

    private func isDueTodayOrOverdue(_ item: TodoItem.Snapshot) -> Bool {
        guard let due = item.dueDate else { return false }
        return due.startOfDay <= entry.date.startOfDay
    }

    private func dueState(due: Date, hasDueTime: Bool, now: Date) -> (label: String, isUrgent: Bool) {
        let calendar = Calendar.current
        if due.startOfDay < now.startOfDay {
            return ("期限切れ", true)
        }
        if due.startOfDay == now.startOfDay {
            if hasDueTime && due > now {
                let hours = max(1, calendar.dateComponents([.hour], from: now, to: due).hour ?? 0)
                return ("あと\(hours)時間", true)
            }
            return ("今日まで", true)
        }

        if hasDueTime && due.timeIntervalSince(now) < 24 * 60 * 60 {
            let hours = max(1, calendar.dateComponents([.hour], from: now, to: due).hour ?? 0)
            return ("あと\(hours)時間", false)
        }

        let today = now.startOfDay
        let dueDay = due.startOfDay
        let days = max(1, calendar.dateComponents([.day], from: today, to: dueDay).day ?? 1)
        return ("あと\(days)日", false)
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
