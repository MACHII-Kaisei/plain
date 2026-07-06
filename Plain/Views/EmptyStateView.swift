import SwiftUI

struct EmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(Color(hex: 0x0058bc))
            Text("タスクなし")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: 0x181c23))
            Text("タスクを追加すると、ウィジェットにも表示されます。")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0x717786))
            Button(action: onAdd) {
                Label("タスクを追加", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0xf7f8fb))
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
