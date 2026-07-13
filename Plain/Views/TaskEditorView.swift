import SwiftUI
import SwiftData
import PlainCore

struct TaskEditorView: View {
    enum Mode {
        case new(defaultDue: Date?)
        case edit(TodoItem)
    }

    enum ExpandedPicker {
        case date, time
    }

    let mode: Mode
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @State private var title: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Self.todayStart()
    @State private var hasDueTime: Bool = false
    @State private var dueHour: Int = 9
    @State private var dueMinute: Int = 0
    @State private var expandedPicker: ExpandedPicker?
    @State private var notes: String = ""
    @State private var urlString: String = ""
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var isAddingTag: Bool = false
    @State private var newTagName: String = ""
    @State private var newTagColorIndex: Int = 5
    @FocusState private var titleFocused: Bool

    @Query(sort: \Tag.createdAt) private var allTags: [Tag]

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            contentArea
        }
        .frame(width: 672, height: 580)
        .background(Color(red: 249/255, green: 249/255, blue: 255/255))
        .onAppear {
            switch mode {
            case .new(let defaultDue):
                hasDueDate = defaultDue != nil
                dueDate = defaultDue ?? Self.todayStart()
                hasDueTime = false
            case .edit(let item):
                title = item.title
                notes = item.notes ?? ""
                urlString = item.urlString ?? ""
                hasDueDate = item.dueDate != nil
                dueDate = item.dueDate ?? Self.todayStart()
                hasDueTime = item.hasDueTime
                selectedTagIDs = Set(item.tags.map(\.id))
            }
            if hasDueTime {
                let (h, m) = Self.splitTime(dueDate)
                dueHour = h
                dueMinute = m
            } else {
                dueHour = 9
                dueMinute = 0
            }
            titleFocused = true
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            Text(isEdit ? "タスクを編集" : "新規タスク")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: 0x181c23))
            Spacer()
            Button("キャンセル", action: onClose)
                .buttonStyle(.bordered)
            Button(isEdit ? "保存" : "追加", action: save)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("save-button")
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
    }

    // MARK: - Content

    private var contentArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("タイトルを入力", text: $title)
                        .font(.system(size: 22, weight: .semibold))
                        .textFieldStyle(.plain)
                        .accessibilityIdentifier("title-field")
                        .focused($titleFocused)
                        .onSubmit { save() }
                    Divider()
                }
                .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("メモ")
                    TextEditor(text: $notes)
                        .font(.system(size: 13))
                        .scrollContentBackground(.hidden)
                        .contentMargins(8, for: .scrollContent)
                        .scrollIndicators(.hidden)
                        .frame(height: 96)
                        .padding(4)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                        .fieldBorder()
                }

                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        urlSection
                        tagSection
                    }
                    .frame(maxWidth: .infinity)

                    dueDateSection
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - URL

    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("参照URL")
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                TextField("URLを入力", text: $urlString)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .textContentType(.URL)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .fieldBorder()
        }
    }

    // MARK: - Tags

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("タグ")
            VStack(alignment: .leading, spacing: 8) {
                if !allTags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(allTags) { tag in
                            let color = TagColor.from(index: tag.colorIndex)
                            let isSelected = selectedTagIDs.contains(tag.id)
                            Button {
                                if isSelected {
                                    selectedTagIDs.remove(tag.id)
                                } else {
                                    selectedTagIDs.insert(tag.id)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                    Text(tag.name)
                                }
                                .font(.caption)
                                .foregroundStyle(color.foregroundColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(color.backgroundColor, in: Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? color.foregroundColor : .clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if isAddingTag {
                    VStack(spacing: 8) {
                        TextField("タグ名", text: $newTagName)
                            .textFieldStyle(.plain)
                            .font(.callout)
                            .padding(8)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                            .fieldBorder()

                        tagColorGrid

                        HStack {
                            Button("キャンセル") {
                                isAddingTag = false
                                newTagName = ""
                            }
                            .font(.caption)
                            Button("追加") {
                                let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                let store = TodoStore(container: context.container)
                                let tag = store.addTag(name: trimmed, colorIndex: newTagColorIndex)
                                selectedTagIDs.insert(tag.id)
                                isAddingTag = false
                                newTagName = ""
                            }
                            .font(.caption)
                            .buttonStyle(.borderedProminent)
                            .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(8)
                    .background(Color(hex: 0xf7f8fb))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Button {
                        isAddingTag = true
                        newTagName = ""
                        newTagColorIndex = 5
                    } label: {
                        Label("新規タグ", systemImage: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
            }
            .padding(12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .fieldBorder()
        }
    }

    private var tagColorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(24), spacing: 6), count: 6), spacing: 6) {
            ForEach(TagColor.allCases, id: \.rawValue) { color in
                Circle()
                    .fill(color.foregroundColor)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .overlay {
                        if newTagColorIndex == color.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        newTagColorIndex = color.rawValue
                    }
            }
        }
    }

    // MARK: - Due Date + Notification

    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("期日")
            VStack(spacing: 0) {
                HStack {
                    Text("期日を設定")
                        .font(.callout)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { hasDueDate },
                        set: { newValue in
                            withAnimation { hasDueDate = newValue }
                            if !newValue {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    expandedPicker = nil
                                }
                            }
                        }
                    ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                if hasDueDate {
                    Divider().padding(.horizontal, 12)

                    HStack {
                        Text("日付")
                            .font(.callout)
                        Spacer()
                        pickerChip(formattedDate, isActive: expandedPicker == .date) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedPicker = expandedPicker == .date ? nil : .date
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    if expandedPicker == .date {
                        CalendarMonthView(selectedDate: $dueDate)
                            .padding(12)
                    }

                    Divider().padding(.horizontal, 12)

                    HStack {
                        Text("時刻を設定")
                            .font(.callout)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { hasDueTime },
                            set: { newValue in
                                withAnimation { hasDueTime = newValue }
                                if newValue {
                                    dueHour = 9
                                    dueMinute = 0
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedPicker = .time
                                    }
                                } else if expandedPicker == .time {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedPicker = nil
                                    }
                                }
                            }
                        ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    if hasDueTime {
                        Divider().padding(.horizontal, 12)

                        HStack {
                            Text("時刻")
                                .font(.callout)
                            Spacer()
                            pickerChip(formattedTime, isActive: expandedPicker == .time) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    expandedPicker = expandedPicker == .time ? nil : .time
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)

                        if expandedPicker == .time {
                            WheelTimePicker(hour: $dueHour, minute: $dueMinute)
                        }
                    }
                }

            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .fieldBorder()
        }
    }

    private func pickerChip(_ text: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.callout.monospacedDigit())
                .foregroundStyle(isActive ? Color.accentColor : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 238/255, green: 241/255, blue: 246/255),
                            in: RoundedRectangle(cornerRadius: 7))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(red: 113/255, green: 119/255, blue: 134/255))
            .padding(.horizontal, 4)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日(E)"
        return f.string(from: dueDate)
    }

    private var formattedTime: String {
        String(format: "%02d:%02d", dueHour, dueMinute)
    }

    private static func splitTime(_ date: Date) -> (Int, Int) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 9, c.minute ?? 0)
    }

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let store = TodoStore(container: context.container)

        // Build dueDate
        let dueForSave: Date?
        if hasDueDate {
            if hasDueTime {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
                components.hour = dueHour
                components.minute = dueMinute
                dueForSave = Calendar.current.date(from: components) ?? dueDate
            } else {
                dueForSave = Calendar.current.startOfDay(for: dueDate)
            }
        } else {
            dueForSave = nil
        }

        let notesTrimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlTrimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesForSave: String? = notesTrimmed.isEmpty ? nil : notesTrimmed
        let urlForSave: String? = urlTrimmed.isEmpty ? nil : urlTrimmed

        // Resolve selected tags from the latest store state.
        // `@Query` updates can lag briefly while a sheet is open.
        let tagsForSave = store.fetchAllTags().filter { selectedTagIDs.contains($0.id) }

        switch mode {
        case .new:
            store.add(title: trimmed,
                      dueDate: dueForSave,
                      notes: notesForSave,
                      urlString: urlForSave,
                      hasDueTime: hasDueTime,
                      tags: tagsForSave)
        case .edit(let item):
            store.update(item,
                         title: trimmed,
                         dueDate: Optional(dueForSave),
                         notes: Optional(notesForSave),
                         urlString: Optional(urlForSave),
                         hasDueTime: hasDueTime,
                         tags: tagsForSave)
        }
        onClose()
    }

    private static func todayStart() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    private static func todayAtNine() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? Date()
    }
}

// MARK: - Card shadow

private extension View {
    func fieldBorder() -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: 0xecedf3), lineWidth: 1)
        )
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

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private struct ArrangeResult {
        var positions: [CGPoint]
        var size: CGSize
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x + size.width)
            x += size.width + spacing
        }

        return ArrangeResult(
            positions: positions,
            size: CGSize(width: maxX, height: y + rowHeight)
        )
    }
}
