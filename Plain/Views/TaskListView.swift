import SwiftUI
import SwiftData
import PlainCore

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @State private var sidebarSelection: SidebarItem = .today
    @State private var editorSheet: EditorSheet? = nil
    @State private var searchText: String = ""
    @State private var selectedItemID: UUID? = nil

    enum EditorSheet: Identifiable {
        case new
        case edit(TodoItem)
        var id: String {
            switch self {
            case .new: "new"
            case .edit(let i): i.id.uuidString
            }
        }
    }

    private var defaultDueForNew: Date? {
        let hour = UserDefaults.standard.integer(forKey: "defaultNotificationHour")
        let h = hour == 0 ? 9 : hour
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let base = cal.date(bySettingHour: h, minute: 0, second: 0, of: today) else { return nil }
        switch sidebarSelection {
        case .today: return base
        case .thisWeek: return base
        case .upcoming, .completed: return nil
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $sidebarSelection)
        } detail: {
            MainListView(
                sidebarSelection: sidebarSelection,
                searchText: searchText,
                selectedItemID: $selectedItemID,
                onNew: { editorSheet = .new },
                onEdit: { editorSheet = .edit($0) }
            )
            .overlay(alignment: .bottomTrailing) {
                if sidebarSelection != .completed {
                    Button(action: { editorSheet = .new }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor, in: Circle())
                            .shadow(radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("新しいタスクを追加")
                    .accessibilityIdentifier("add-button")
                    .padding(20)
                }
            }
            .searchable(text: $searchText)
        }
        .sheet(item: $editorSheet) { sheet in
            switch sheet {
            case .new:
                TaskEditorView(mode: .new(defaultDue: defaultDueForNew)) { editorSheet = nil }
            case .edit(let item):
                TaskEditorView(mode: .edit(item)) { editorSheet = nil }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .plainNewTask)) { _ in
            editorSheet = .new
        }
    }
}

private struct MainListView: View {
    let sidebarSelection: SidebarItem
    let searchText: String
    @Binding var selectedItemID: UUID?
    let onNew: () -> Void
    let onEdit: (TodoItem) -> Void
    @Environment(\.modelContext) private var context
    @Query private var items: [TodoItem]

    init(
        sidebarSelection: SidebarItem,
        searchText: String,
        selectedItemID: Binding<UUID?>,
        onNew: @escaping () -> Void,
        onEdit: @escaping (TodoItem) -> Void
    ) {
        self.sidebarSelection = sidebarSelection
        self.searchText = searchText
        _selectedItemID = selectedItemID
        self.onNew = onNew
        self.onEdit = onEdit
        if sidebarSelection == .completed {
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            let distantPast = Date.distantPast
            _items = Query(filter: #Predicate<TodoItem> {
                $0.isCompleted && ($0.completedAt ?? distantPast) > sevenDaysAgo
            })
        } else {
            _items = Query(filter: #Predicate<TodoItem> { !$0.isCompleted })
        }
    }

    private var store: TodoStore { TodoStore(container: context.container) }
    private var selectedItem: TodoItem? {
        guard let selectedItemID else { return nil }
        return items.first(where: { $0.id == selectedItemID })
    }

    private var filteredItems: [TodoItem] {
        let now = Date()
        let sectionFiltered: [TodoItem]
        switch sidebarSelection {
        case .today:
            sectionFiltered = items.filter { TaskClassifier.classify(item: $0, now: now) == .today }
        case .thisWeek:
            let cal = Calendar.current
            let todayStart = cal.startOfDay(for: now)
            let weekLater = cal.date(byAdding: .day, value: 7, to: todayStart)!
            sectionFiltered = items.filter {
                guard let due = $0.dueDate else { return false }
                return due >= todayStart && due < weekLater
            }
        case .upcoming:
            sectionFiltered = items
        case .completed:
            sectionFiltered = items
        }
        let base = searchText.isEmpty ? sectionFiltered : sectionFiltered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        return base.sorted(by: sidebarSelection == .completed ? TodoItemSort.compareCompleted : TodoItemSort.compareActive)
    }

    var body: some View {
        Group {
            if filteredItems.isEmpty && searchText.isEmpty {
                if sidebarSelection == .completed {
                    Text("完了したタスクはありません").foregroundStyle(.secondary)
                } else {
                    EmptyStateView(onAdd: onNew)
                }
            } else if filteredItems.isEmpty {
                Text("該当するタスクはありません").foregroundStyle(.secondary)
            } else {
                List(selection: $selectedItemID) {
                    ForEach(filteredItems, id: \.id) { item in
                        TaskRowView(
                            item: item,
                            onToggle: { store.toggleComplete(item) },
                            onEdit: { onEdit(item) }
                        )
                            .contextMenu {
                                Button("編集") { onEdit(item) }
                                Button("複製") { _ = store.duplicate(item) }
                                Divider()
                                Button("削除", role: .destructive) { store.delete(item) }
                            }
                            .onTapGesture(count: 1) { onEdit(item) }
                            .tag(item.id)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .plainToggleComplete)) { _ in
            guard let item = selectedItem else { return }
            store.toggleComplete(item)
        }
        .onReceive(NotificationCenter.default.publisher(for: .plainEditSelected)) { _ in
            guard let item = selectedItem else { return }
            onEdit(item)
        }
        .onReceive(NotificationCenter.default.publisher(for: .plainDuplicateSelected)) { _ in
            guard let item = selectedItem else { return }
            _ = store.duplicate(item)
        }
        .onReceive(NotificationCenter.default.publisher(for: .plainDeleteSelected)) { _ in
            guard let item = selectedItem else { return }
            store.delete(item)
        }
        .onReceive(NotificationCenter.default.publisher(for: .plainNewTask)) { _ in
            onNew()
        }
        .onReceive(NotificationCenter.default.publisher(for: .plainOpenTask)) { note in
            guard let id = note.object as? UUID,
                  let item = items.first(where: { $0.id == id }) else { return }
            onEdit(item)
        }
    }
}
