import SwiftUI
import SwiftData
import PlainCore

struct FilterBarView: View {
    @Bindable var filterState: FilterState
    let sidebarSelection: SidebarItem
    @Query(sort: \Tag.createdAt) private var allTags: [Tag]

    var body: some View {
        HStack(spacing: 8) {
            // Priority filter
            Menu {
                Button("すべて") {
                    filterState.priorities = []
                }
                Divider()
                ForEach([Priority.high, .medium, .low], id: \.self) { p in
                    Button {
                        if filterState.priorities.contains(p) {
                            filterState.priorities.remove(p)
                        } else {
                            filterState.priorities.insert(p)
                        }
                    } label: {
                        HStack {
                            Text(priorityLabel(p))
                            if filterState.priorities.contains(p) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                filterChip(
                    title: "優先度",
                    count: filterState.priorities.count,
                    isActive: !filterState.priorities.isEmpty
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // Tag filter
            Menu {
                Button("すべて") {
                    filterState.tagIDs = []
                }
                Divider()
                ForEach(allTags) { tag in
                    Button {
                        if filterState.tagIDs.contains(tag.id) {
                            filterState.tagIDs.remove(tag.id)
                        } else {
                            filterState.tagIDs.insert(tag.id)
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(TagColor.from(index: tag.colorIndex).foregroundColor)
                                .frame(width: 8, height: 8)
                            Text(tag.name)
                            if filterState.tagIDs.contains(tag.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                filterChip(
                    title: "タグ",
                    count: filterState.tagIDs.count,
                    isActive: !filterState.tagIDs.isEmpty
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // Due date filter
            let isDueDateDisabled = sidebarSelection == .today || sidebarSelection == .thisWeek
            Menu {
                Button("すべて") {
                    filterState.dueDateFilter = nil
                }
                Divider()
                ForEach(FilterState.DueDateFilter.allCases, id: \.self) { filter in
                    Button {
                        filterState.dueDateFilter = filterState.dueDateFilter == filter ? nil : filter
                    } label: {
                        HStack {
                            Text(filter.label)
                            if filterState.dueDateFilter == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                filterChip(
                    title: "期日",
                    count: filterState.dueDateFilter == nil ? 0 : 1,
                    isActive: filterState.dueDateFilter != nil
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(isDueDateDisabled)
            .opacity(isDueDateDisabled ? 0.5 : 1)

            Spacer()

            // Sort order
            Menu {
                ForEach(TaskSortOrder.allCases, id: \.self) { order in
                    Button {
                        filterState.sortOrder = order
                    } label: {
                        HStack {
                            Text(order.label)
                            if filterState.sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption2)
                    Text(filterState.sortOrder.label)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(red: 241/255, green: 243/255, blue: 254/255))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func filterChip(title: String, count: Int, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Text(count > 0 ? "\(title) (\(count))" : title)
                .font(.caption)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? Color.accentColor.opacity(0.15) : Color(red: 241/255, green: 243/255, blue: 254/255))
        .foregroundStyle(isActive ? Color.accentColor : .secondary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func priorityLabel(_ p: Priority) -> String {
        switch p {
        case .high:   "高"
        case .medium: "中"
        case .low:    "低"
        }
    }
}
