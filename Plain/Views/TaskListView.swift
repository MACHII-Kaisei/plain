import SwiftUI
import SwiftData
import PlainCore

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @State private var sidebarSelection: SidebarItem = .today
    @State private var editorSheet: EditorSheet? = nil
    @State private var searchText: String = ""
    @State private var selectedItemID: UUID? = nil
    @State private var filterState = FilterState()
    @State private var isBulkMode: Bool = false
    @State private var bulkSelection: Set<UUID> = []
    @State private var showTagManager = false
    @State private var showDisplaySettings = false
    @State private var showDeleteCompletedConfirm = false

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
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        switch sidebarSelection {
        case .today: return today
        case .thisWeek: return today
        case .upcoming, .completed: return nil
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $sidebarSelection)
        } detail: {
            VStack(spacing: 0) {
                if sidebarSelection != .completed {
                    FilterBarView(filterState: filterState, sidebarSelection: sidebarSelection)
                    Divider()
                }

                if isBulkMode {
                    BulkActionBar(
                        selectedItems: $bulkSelection,
                        totalCount: 0,
                        onSelectAll: { /* handled in MainListView */ },
                        onTagAction: { _ in },
                        onComplete: {},
                        onDelete: {},
                        onExit: { exitBulkMode() }
                    )
                    // Note: actual actions are handled in MainListView via notifications
                    Divider()
                }

                MainListView(
                    sidebarSelection: sidebarSelection,
                    searchText: searchText,
                    selectedItemID: $selectedItemID,
                    filterState: filterState,
                    isBulkMode: $isBulkMode,
                    bulkSelection: $bulkSelection,
                    onNew: { editorSheet = .new },
                    onEdit: { editorSheet = .edit($0) }
                )
                .overlay(alignment: .bottomTrailing) {
                    if sidebarSelection != .completed && !isBulkMode {
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            enterBulkMode()
                        } label: {
                            Label("一括選択", systemImage: "checkmark.circle")
                        }

                        Divider()

                        Button {
                            showTagManager = true
                        } label: {
                            Label("タグ管理", systemImage: "tag")
                        }

                        Button {
                            showDisplaySettings = true
                        } label: {
                            Label("表示設定", systemImage: "eye")
                        }

                        Menu("データ管理") {
                            Button {
                                CSVExporter.export(context: context)
                            } label: {
                                Label("エクスポート (CSV)", systemImage: "square.and.arrow.up")
                            }

                            Button(role: .destructive) {
                                showDeleteCompletedConfirm = true
                            } label: {
                                Label("完了済みを一括削除", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(item: $editorSheet) { sheet in
            switch sheet {
            case .new:
                TaskEditorView(mode: .new(defaultDue: defaultDueForNew)) { editorSheet = nil }
            case .edit(let item):
                TaskEditorView(mode: .edit(item)) { editorSheet = nil }
            }
        }
        .sheet(isPresented: $showTagManager) {
            TagManagerView()
        }
        .sheet(isPresented: $showDisplaySettings) {
            DisplaySettingsView()
        }
        .alert("完了済みを一括削除", isPresented: $showDeleteCompletedConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                let store = TodoStore(container: context.container)
                let count = store.deleteAllCompleted()
                _ = count
            }
        } message: {
            Text("完了済みタスクをすべて削除します。この操作は取り消せません。")
        }
        .onReceive(NotificationCenter.default.publisher(for: .plainNewTask)) { _ in
            editorSheet = .new
        }
    }

    private func enterBulkMode() {
        isBulkMode = true
        bulkSelection = []
    }

    private func exitBulkMode() {
        isBulkMode = false
        bulkSelection = []
    }
}

// MARK: - MainListView

private struct MainListView: View {
    let sidebarSelection: SidebarItem
    let searchText: String
    @Binding var selectedItemID: UUID?
    @Bindable var filterState: FilterState
    @Binding var isBulkMode: Bool
    @Binding var bulkSelection: Set<UUID>
    let onNew: () -> Void
    let onEdit: (TodoItem) -> Void
    @Environment(\.modelContext) private var context
    @Query private var items: [TodoItem]
    @AppStorage("showNotesInRow") private var showNotesInRow: Bool = true
    @AppStorage("showTagsInRow") private var showTagsInRow: Bool = true

    init(
        sidebarSelection: SidebarItem,
        searchText: String,
        selectedItemID: Binding<UUID?>,
        filterState: FilterState,
        isBulkMode: Binding<Bool>,
        bulkSelection: Binding<Set<UUID>>,
        onNew: @escaping () -> Void,
        onEdit: @escaping (TodoItem) -> Void
    ) {
        self.sidebarSelection = sidebarSelection
        self.searchText = searchText
        _selectedItemID = selectedItemID
        self.filterState = filterState
        _isBulkMode = isBulkMode
        _bulkSelection = bulkSelection
        self.onNew = onNew
        self.onEdit = onEdit

        let retentionDays = UserDefaults.standard.object(forKey: "completedRetentionDays") as? Int ?? 7
        if sidebarSelection == .completed {
            let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date())!
            let distantPast = Date.distantPast
            _items = Query(filter: #Predicate<TodoItem> {
                $0.isCompleted && ($0.completedAt ?? distantPast) > cutoff
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

        // Search
        let searched = searchText.isEmpty ? sectionFiltered : sectionFiltered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }

        // Apply filters (not for completed tab)
        let filtered: [TodoItem]
        if sidebarSelection == .completed {
            filtered = searched
        } else {
            filtered = filterState.apply(to: searched, now: now)
        }

        // Sort
        if sidebarSelection == .completed {
            return filtered.sorted(by: TodoItemSort.compareCompleted)
        } else {
            return filtered.sorted(by: TodoItemSort.comparator(for: filterState.sortOrder))
        }
    }

    var body: some View {
        Group {
            if filteredItems.isEmpty && searchText.isEmpty && !filterState.hasActiveFilters {
                if sidebarSelection == .completed {
                    Text("完了したタスクはありません").foregroundStyle(.secondary)
                } else {
                    EmptyStateView(onAdd: onNew)
                }
            } else if filteredItems.isEmpty {
                Text("該当するタスクはありません").foregroundStyle(.secondary)
            } else {
                List(selection: isBulkMode ? $bulkSelection : nil) {
                    ForEach(filteredItems, id: \.id) { item in
                        TaskRowView(
                            item: item,
                            showNotes: showNotesInRow,
                            showTags: showTagsInRow,
                            isBulkMode: isBulkMode,
                            isSelected: bulkSelection.contains(item.id),
                            onToggle: { store.toggleComplete(item) },
                            onEdit: { onEdit(item) },
                            onBulkToggle: {
                                if bulkSelection.contains(item.id) {
                                    bulkSelection.remove(item.id)
                                } else {
                                    bulkSelection.insert(item.id)
                                }
                            }
                        )
                            .contextMenu {
                                if isBulkMode {
                                    Button("タグを追加...") { }
                                    Button("完了にする") {
                                        let selected = filteredItems.filter { bulkSelection.contains($0.id) }
                                        store.batchToggleComplete(selected)
                                        exitBulkMode()
                                    }
                                    Button("削除（\(bulkSelection.count)件）", role: .destructive) {
                                        let selected = filteredItems.filter { bulkSelection.contains($0.id) }
                                        store.batchDelete(selected)
                                        exitBulkMode()
                                    }
                                } else {
                                    Button("編集") { onEdit(item) }
                                    Button("複製") { _ = store.duplicate(item) }
                                    Divider()
                                    Button("削除", role: .destructive) { store.delete(item) }
                                }
                            }
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

    private func exitBulkMode() {
        isBulkMode = false
        bulkSelection = []
    }
}
