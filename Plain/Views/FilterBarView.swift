import SwiftUI
import SwiftData
import PlainCore

struct FilterBarView: View {
    @Bindable var filterState: FilterState
    let sidebarSelection: SidebarItem
    @Query(sort: \Tag.createdAt) private var allTags: [Tag]

    var body: some View {
        HStack(spacing: 8) {
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
                    icon: "tag",
                    title: "タグ",
                    count: filterState.tagIDs.count,
                    isActive: !filterState.tagIDs.isEmpty
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            let isDueDateDisabled = sidebarSelection == .thisWeek
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
                    icon: "calendar",
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
                        .font(.system(size: 10, weight: .medium))
                    Text(filterState.sortOrder.label)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .foregroundStyle(Color(hex: 0x414755))
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(Color(hex: 0xecedf3), lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: 0xf7f8fb))
    }

    @ViewBuilder
    private func filterChip(icon: String, title: String, count: Int, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(count > 0 ? "\(title) (\(count))" : title)
                .font(.system(size: 12, weight: .medium))
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .semibold))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(isActive ? Color(hex: 0xe1efff) : Color.white, in: Capsule())
        .foregroundStyle(isActive ? Color(hex: 0x0058bc) : Color(hex: 0x717786))
        .overlay(Capsule().stroke(isActive ? Color(hex: 0xa1caff) : Color(hex: 0xecedf3), lineWidth: 1))
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
