import SwiftUI
import SwiftData
import PlainCore

struct BulkActionBar: View {
    @Binding var selectedItems: Set<UUID>
    let totalCount: Int
    let completionActionTitle: String
    let completionActionSystemImage: String
    let onSelectAll: () -> Void
    let onTagAction: (Tag) -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onExit: () -> Void

    @Query(sort: \Tag.createdAt) private var allTags: [Tag]
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelectAll) {
                Label("全選択", systemImage: selectedItems.count == totalCount ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(hex: 0x0058bc))

            Text("\(selectedItems.count)件選択中")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: 0x414755))

            Spacer()

            Menu {
                ForEach(allTags) { tag in
                    Button {
                        onTagAction(tag)
                    } label: {
                        HStack {
                            Circle()
                                .fill(TagColor.from(index: tag.colorIndex).foregroundColor)
                                .frame(width: 8, height: 8)
                            Text(tag.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                        .font(.system(size: 11, weight: .medium))
                    Text("タグ付け")
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(Color(hex: 0x414755))
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(Color(hex: 0xecedf3), lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(selectedItems.isEmpty)

            Button {
                onComplete()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: completionActionSystemImage)
                        .font(.system(size: 11, weight: .medium))
                    Text(completionActionTitle)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(hex: 0x0058bc))
            .disabled(selectedItems.isEmpty)

            Button {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .medium))
                    Text("削除")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(hex: 0xc64f00))
            .disabled(selectedItems.isEmpty)

            Button {
                onExit()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(hex: 0x717786))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: 0xf7f8fb))
        .alert("タスクを削除", isPresented: $showDeleteConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) { onDelete() }
        } message: {
            Text("\(selectedItems.count)件のタスクを削除します。この操作は取り消せません。")
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
