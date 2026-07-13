import SwiftUI

struct WheelTimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    private let rowHeight: CGFloat = 32
    private let visibleHeight: CGFloat = 180

    private var minuteValues: [Int] {
        var values = stride(from: 0, through: 55, by: 5).map { $0 }
        if !values.contains(minute) {
            values.append(minute)
            values.sort()
        }
        return values
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: 0xeef1f6))
                .frame(height: rowHeight + 6)

            HStack(spacing: 0) {
                WheelColumn(values: Array(0...23), selection: $hour,
                            rowHeight: rowHeight, visibleHeight: visibleHeight)
                Text(":")
                    .font(.system(size: 20, weight: .semibold).monospacedDigit())
                WheelColumn(values: minuteValues, selection: $minute,
                            rowHeight: rowHeight, visibleHeight: visibleHeight)
            }
        }
        .frame(height: visibleHeight)
    }
}

private struct WheelColumn: View {
    let values: [Int]
    @Binding var selection: Int
    let rowHeight: CGFloat
    let visibleHeight: CGFloat

    @State private var scrolledID: Int?

    init(values: [Int], selection: Binding<Int>, rowHeight: CGFloat, visibleHeight: CGFloat) {
        self.values = values
        self._selection = selection
        self.rowHeight = rowHeight
        self.visibleHeight = visibleHeight
        self._scrolledID = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(values, id: \.self) { value in
                    Text(String(format: "%02d", value))
                        .font(.system(size: value == selection ? 20 : 16,
                                      weight: value == selection ? .semibold : .regular)
                              .monospacedDigit())
                        .foregroundStyle(value == selection ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: rowHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation { scrolledID = value }
                        }
                        .id(value)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledID, anchor: .center)
        .safeAreaPadding(.vertical, (visibleHeight - rowHeight) / 2)
        .frame(width: 88, height: visibleHeight)
        .onChange(of: scrolledID) { _, newValue in
            if let newValue, newValue != selection { selection = newValue }
        }
        .onAppear { scrolledID = selection }
        .onChange(of: selection) { _, newValue in
            if scrolledID != newValue { scrolledID = newValue }
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
    @Previewable @State var minute = 30
    return WheelTimePicker(hour: $hour, minute: $minute)
        .padding()
        .frame(width: 300)
}
