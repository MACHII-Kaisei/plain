import SwiftUI

struct CalendarMonthView: View {
    @Binding var selectedDate: Date
    @State private var displayedMonth: Date

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "ja_JP")
        c.firstWeekday = 1 // 日曜始まり
        return c
    }

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        _displayedMonth = State(initialValue: selectedDate.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            weekdayRow
            dayGrid
        }
    }

    private var header: some View {
        HStack {
            Text(monthTitle)
                .font(.system(size: 16, weight: .bold))
            Spacer()
            Button { moveMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
            Button { moveMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                  spacing: 4) {
            ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 32)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        return Button {
            select(day)
        } label: {
            Text("\(calendar.component(.day, from: day))")
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : (isToday ? Color.accentColor : .primary))
                .frame(width: 32, height: 32)
                .background {
                    if isSelected {
                        Circle().fill(Color.accentColor)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logic

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: displayedMonth)
    }

    private func moveMonth(by offset: Int) {
        if let next = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = next
        }
    }

    /// 表示月のセル配列。先頭に当月 1 日の曜日分だけ nil を詰める。
    private func daysInMonth() -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth),
              let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth)
        else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start) // 1=Sun
        let leading = firstWeekday - calendar.firstWeekday
        var cells: [Date?] = Array(repeating: nil, count: max(0, leading))
        for day in dayRange {
            cells.append(calendar.date(byAdding: .day, value: day - 1, to: interval.start))
        }
        return cells
    }

    /// 時刻成分を維持したまま年月日のみ差し替える
    private func select(_ day: Date) {
        var components = calendar.dateComponents([.hour, .minute], from: selectedDate)
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        components.year = dayComponents.year
        components.month = dayComponents.month
        components.day = dayComponents.day
        if let merged = calendar.date(from: components) {
            selectedDate = merged
        }
    }
}

#Preview {
    @Previewable @State var date = Date()
    return CalendarMonthView(selectedDate: $date)
        .padding()
        .frame(width: 300)
}
