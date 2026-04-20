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
    @State private var dueDate: Date = Self.todayAtNine()
    @State private var hourString: String = "09"
    @State private var minuteString: String = "00"
    @State private var showCalendar: Bool = false
    @State private var priority: Priority = .medium
    @State private var notificationEnabled: Bool = true
    @State private var notes: String = ""
    @State private var urlString: String = ""
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            contentArea
        }
        .frame(width: 672, height: 520)
        .background(Color(red: 249/255, green: 249/255, blue: 255/255))
        .onAppear {
            switch mode {
            case .new(let defaultDue):
                hasDueDate = defaultDue != nil
                dueDate = defaultDue ?? Self.todayAtNine()
            case .edit(let item):
                title = item.title
                priority = item.priority
                notes = item.notes ?? ""
                urlString = item.urlString ?? ""
                notificationEnabled = item.notificationEnabled
                hasDueDate = item.dueDate != nil
                dueDate = item.dueDate ?? Self.todayAtNine()
            }
            let (h, m) = Self.splitTime(dueDate)
            hourString = h
            minuteString = m
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
                // Left: URL + Priority
                VStack(alignment: .leading, spacing: 16) {
                    urlSection
                    prioritySection
                }
                .frame(maxWidth: .infinity)

                // Right: Due date + Notification
                dueDateSection
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(28)
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

    // MARK: - Due Date + Notification

    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("期日と通知")
            VStack(spacing: 0) {
                // Toggle row
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

                    // Date + Time on one line
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
                                    applyTime()
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
                                    applyTime()
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }

                Divider().padding(.horizontal, 12)

                // Notification toggle row
                HStack {
                    Image(systemName: "bell")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    Text("通知")
                        .font(.callout)
                    Spacer()
                    Toggle("", isOn: $notificationEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .disabled(!hasDueDate)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
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

    private func applyTime() {
        guard let h = Int(hourString), h >= 0, h <= 23,
              let m = Int(minuteString), m >= 0, m <= 59 else { return }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = h
        components.minute = m
        if let updated = Calendar.current.date(from: components) {
            dueDate = updated
        }
    }

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func save() {
        applyTime()
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let store = TodoStore(container: context.container)
        let dueForSave: Date? = hasDueDate ? dueDate : nil
        let notesTrimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlTrimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesForSave: String? = notesTrimmed.isEmpty ? nil : notesTrimmed
        let urlForSave: String? = urlTrimmed.isEmpty ? nil : urlTrimmed

        switch mode {
        case .new:
            store.add(title: trimmed,
                      priority: priority,
                      dueDate: dueForSave,
                      notes: notesForSave,
                      urlString: urlForSave,
                      notificationEnabled: notificationEnabled)
        case .edit(let item):
            store.update(item,
                         title: trimmed,
                         priority: priority,
                         dueDate: Optional(dueForSave),
                         notes: Optional(notesForSave),
                         urlString: Optional(urlForSave),
                         notificationEnabled: notificationEnabled)
        }
        onClose()
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
