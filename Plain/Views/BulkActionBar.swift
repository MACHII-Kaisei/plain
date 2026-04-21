import SwiftUI
import SwiftData
import PlainCore

struct BulkActionBar: View {
    @Binding var selectedItems: Set<UUID>
    let totalCount: Int
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
                Text("全選択")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            Text("\(selectedItems.count)件選択中")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            // Tag action
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
                        .font(.caption)
                    Text("タグ付け")
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(red: 241/255, green: 243/255, blue: 254/255))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(selectedItems.isEmpty)

            Button {
                onComplete()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                    Text("完了にする")
                        .font(.caption)
                }
            }
            .buttonStyle(.bordered)
            .disabled(selectedItems.isEmpty)

            Button {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.caption)
                    Text("削除")
                        .font(.caption)
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(selectedItems.isEmpty)

            Button {
                onExit()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 241/255, green: 243/255, blue: 254/255))
        .alert("タスクを削除", isPresented: $showDeleteConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) { onDelete() }
        } message: {
            Text("\(selectedItems.count)件のタスクを削除します。この操作は取り消せません。")
        }
    }
}
