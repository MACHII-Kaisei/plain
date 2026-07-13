import SwiftUI

struct TimeListPicker: View {
    @Binding var hour: Int
    @Binding var minute: Int
    let onSelect: () -> Void

    @State private var hoveredIndex: Int?

    private let rowHeight: CGFloat = 32
    private let visibleHeight: CGFloat = 200

    init(hour: Binding<Int>, minute: Binding<Int>, onSelect: @escaping () -> Void) {
        self._hour = hour
        self._minute = minute
        self.onSelect = onSelect
    }

    private var times: [(hour: Int, minute: Int)] {
        var values: [(Int, Int)] = []
        for h in 0..<24 {
            for m in stride(from: 0, to: 60, by: 15) {
                values.append((h, m))
            }
        }
        if !values.contains(where: { $0.0 == hour && $0.1 == minute }) {
            values.append((hour, minute))
            values.sort { lhs, rhs in
                if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
                return lhs.1 < rhs.1
            }
        }
        return values
    }

    private func id(for time: (hour: Int, minute: Int)) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
    }

    private var selectedID: String {
        String(format: "%02d:%02d", hour, minute)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(times.enumerated()), id: \.offset) { index, time in
                        let rowID = id(for: time)
                        let isSelected = rowID == selectedID
                        let isHovered = hoveredIndex == index

                        HStack(spacing: 0) {
                            Text(rowID)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular)
                                      .monospacedDigit())
                                .foregroundStyle(isSelected ? Color.accentColor : .primary)

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(height: rowHeight)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color.accentColor.opacity(0.12)
                                      : (isHovered ? Color(hex: 0xeef1f6) : Color.clear))
                        )
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            hoveredIndex = hovering ? index : (hoveredIndex == index ? nil : hoveredIndex)
                        }
                        .onTapGesture {
                            hour = time.hour
                            minute = time.minute
                            onSelect()
                        }
                        .id(rowID)
                    }
                }
            }
            .frame(height: visibleHeight)
            .onAppear {
                proxy.scrollTo(selectedID, anchor: .center)
            }
        }
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

#Preview {
    @Previewable @State var hour = 16
    @Previewable @State var minute = 37
    return TimeListPicker(hour: $hour, minute: $minute) {}
        .padding()
        .frame(width: 300)
}
