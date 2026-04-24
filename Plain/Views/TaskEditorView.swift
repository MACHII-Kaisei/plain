import SwiftUI
import SwiftData
import PlainCore

struct TaskEditorView: View {
    enum Mode {
        case new(defaultDue: Date?)
        case edit(TodoItem)
    }

    let mode: Mode
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @State private var title: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Self.todayStart()
    @State private var hasDueTime: Bool = false
    @State private var hourString: String = "09"
    @State private var minuteString: String = "00"
    @State private var showCalendar: Bool = false
    @State private var priority: Priority = .medium
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
                priority = item.priority
                notes = item.notes ?? ""
                urlString = item.urlString ?? ""
                hasDueDate = item.dueDate != nil
                dueDate = item.dueDate ?? Self.todayStart()
                hasDueTime = item.hasDueTime
                selectedTagIDs = Set(item.tags.map(\.id))
            }
            if hasDueTime {
                let (h, m) = Self.splitTime(dueDate)
                hourString = h
                minuteString = m
            } else {
                hourString = "09"
                minuteString = "00"
            }
            titleFocused = true
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
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
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.5))
    }

    // MARK: - Content

    private var contentArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                VStack(alignment: .leading, spacing: 12) {
                    TextField("タイトルを入力", text: $title)
                        .font(.system(size: 24, weight: .medium))
                        .textFieldStyle(.plain)
                        .accessibilityIdentifier("title-field")
                        .focused($titleFocused)
                        .onSubmit { save() }
                    Divider()
                }

                // Memo
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("メモ")
                    TextEditor(text: $notes)
                        .frame(height: 90)
                        .scrollIndicators(.hidden)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .cardShadow()
                }

                // Bottom 2 columns
                HStack(alignment: .top, spacing: 20) {
                    // Left: URL + Priority + Tags
                    VStack(alignment: .leading, spacing: 16) {
                        urlSection
                        prioritySection
                        tagSection
                    }
                    .frame(maxWidth: .infinity)

                    // Right: Due date + Notification
                    dueDateSection
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(28)
        }
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .cardShadow()
        }
    }

    // MARK: - Priority

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("優先度")
            HStack(spacing: 0) {
                ForEach([Priority.low, .medium, .high], id: \.self) { p in
                    Button {
                        priority = p
                    } label: {
                        Text(p.label)
                            .font(.system(size: 14, weight: priority == p ? .semibold : .regular))
                            .foregroundStyle(priority == p ? Color.primary : Color.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(priority == p ? Color.white : Color.clear)
                    )
                    .shadow(color: priority == p ? .black.opacity(0.12) : .clear, radius: 4, x: 0, y: 2)
                }
            }
            .padding(4)
            .background(Color(red: 241/255, green: 243/255, blue: 254/255))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Tags

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("タグ")
            VStack(alignment: .leading, spacing: 8) {
                // Existing tags as chips
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
                                .background(color.backgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSelected ? color.foregroundColor : .clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Add new tag inline
                if isAddingTag {
                    VStack(spacing: 8) {
                        TextField("タグ名", text: $newTagName)
                            .textFieldStyle(.plain)
                            .font(.callout)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

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
                    .background(Color(red: 241/255, green: 243/255, blue: 254/255))
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
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .cardShadow()
        }
    }

    private var tagColorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(24), spacing: 6), count: 6), spacing: 6) {
            ForEach(TagColor.allCases, id: \.rawValue) { color in
                Circle()
                    .fill(color.foregroundColor)
                    .frame(width: 20, height: 20)
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
                // Toggle row - due date
                HStack {
                    Text("期日を設定")
                        .font(.callout)
                    Spacer()
                    Toggle("", isOn: $hasDueDate.animation())
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                if hasDueDate {
                    Divider().padding(.horizontal, 12)

                    // Date row
                    HStack(spacing: 12) {
                        Button {
                            showCalendar.toggle()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                                    .font(.callout)
                                Text(formattedDate)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showCalendar) {
                            calendarPopover
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    Divider().padding(.horizontal, 12)

                    // Toggle row - time
                    HStack {
                        Text("時刻を設定")
                            .font(.callout)
                        Spacer()
                        Toggle("", isOn: $hasDueTime.animation())
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    if hasDueTime {
                        Divider().padding(.horizontal, 12)

                        // Time input row
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                                .frame(width: 16, height: 20)
                            TextField("09", text: $hourString)
                                .textFieldStyle(.plain)
                                .font(.callout.monospacedDigit())
                                .multilineTextAlignment(.center)
                                .frame(width: 24, height: 20)
                                .onChange(of: hourString) { _, v in
                                    let digits = v.filter(\.isNumber)
                                    let clamped: String
                                    if let n = Int(digits) {
                                        clamped = String(format: "%02d", min(n, 23))
                                    } else {
                                        clamped = digits.isEmpty ? "" : digits
                                    }
                                    if clamped != hourString { hourString = clamped }
                                }
                            Text(":")
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.primary)
                                .frame(height: 20)
                            TextField("00", text: $minuteString)
                                .textFieldStyle(.plain)
                                .font(.callout.monospacedDigit())
                                .multilineTextAlignment(.center)
                                .frame(width: 24, height: 20)
                                .onChange(of: minuteString) { _, v in
                                    let digits = v.filter(\.isNumber)
                                    let clamped: String
                                    if let n = Int(digits) {
                                        clamped = String(format: "%02d", min(n, 59))
                                    } else {
                                        clamped = digits.isEmpty ? "" : digits
                                    }
                                    if clamped != minuteString { minuteString = clamped }
                                }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                }

            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .cardShadow()
        }
    }

    private var calendarPopover: some View {
        VStack(spacing: 16) {
            Text("期日を選択")
                .font(.headline)
            DatePicker("", selection: $dueDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .frame(width: 360)
            Divider()
            HStack {
                Spacer()
                Button("完了") {
                    showCalendar = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(red: 113/255, green: 119/255, blue: 134/255))
            .tracking(0.6)
            .padding(.horizontal, 4)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: dueDate)
    }

    private static func splitTime(_ date: Date) -> (String, String) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (String(format: "%02d", c.hour ?? 9), String(format: "%02d", c.minute ?? 0))
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
                // Apply time
                let h = Int(hourString) ?? 9
                let m = Int(minuteString) ?? 0
                var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
                components.hour = h
                components.minute = m
                dueForSave = Calendar.current.date(from: components) ?? dueDate
            } else {
                // startOfDay only
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
                      priority: priority,
                      dueDate: dueForSave,
                      notes: notesForSave,
                      urlString: urlForSave,
                      hasDueTime: hasDueTime,
                      tags: tagsForSave)
        case .edit(let item):
            store.update(item,
                         title: trimmed,
                         priority: priority,
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

// MARK: - Priority label

private extension Priority {
    var label: String {
        switch self {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }
}

// MARK: - Card shadow

private extension View {
    func cardShadow() -> some View {
        shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        Color(red: 193/255, green: 198/255, blue: 215/255).opacity(0.3),
                        lineWidth: 1
                    )
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
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return ArrangeResult(
            positions: positions,
            size: CGSize(width: maxX, height: y + rowHeight)
        )
    }
}
