import SwiftUI
import SwiftData
import PlainCore

enum SidebarItem: String, Hashable, CaseIterable {
    case today, thisWeek, upcoming, completed

    var title: String {
        switch self {
        case .today: "今日"
        case .thisWeek: "今週"
        case .upcoming: "これから"
        case .completed: "完了済み"
        }
    }

    var systemImage: String {
        switch self {
        case .today: "sun.max"
        case .thisWeek: "calendar.badge.clock"
        case .upcoming: "tray.full"
        case .completed: "checkmark.circle"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem
    @Query(filter: #Predicate<TodoItem> { !$0.isCompleted }) private var activeItems: [TodoItem]
    @Query(filter: #Predicate<TodoItem> { $0.isCompleted }) private var completedItems: [TodoItem]
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        List(selection: $selection) {
            ForEach(SidebarItem.allCases, id: \.self) { item in
                Label {
                    HStack {
                        Text(item.title)
                        Spacer()
                        Text("\(count(for: item))").foregroundStyle(.secondary).font(.caption)
                    }
                } icon: {
                    Image(systemName: item.systemImage)
                }
                .tag(item)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Plain")
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button { openSettings() } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("設定")
                .padding(12)
            }
        }
    }

    private static func isThisWeek(_ date: Date?, now: Date) -> Bool {
        guard let date else { return false }
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: now)
        let weekLater = cal.date(byAdding: .day, value: 7, to: todayStart)!
        return date >= todayStart && date < weekLater
    }

    private func count(for item: SidebarItem) -> Int {
        let now = Date()
        switch item {
        case .today:
            return activeItems.filter { TaskClassifier.classify(item: $0, now: now) == .today }.count
        case .thisWeek:
            return activeItems.filter { Self.isThisWeek($0.dueDate, now: now) }.count
        case .upcoming:
            return activeItems.count
        case .completed:
            return completedItems.count
        }
    }
}
