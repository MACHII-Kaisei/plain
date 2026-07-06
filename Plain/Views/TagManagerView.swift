import SwiftUI
import SwiftData
import PlainCore

struct TagManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.createdAt) private var tags: [Tag]
    @State private var isAddingNew = false
    @State private var newTagName = ""
    @State private var newTagColorIndex = 5
    @State private var editingTag: Tag? = nil
    @State private var editName = ""
    @State private var editColorIndex = 0
    @State private var tagToDelete: Tag? = nil

    private var store: TodoStore { TodoStore(container: context.container) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("タグ管理")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x181c23))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color(hex: 0x717786))
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            if tags.isEmpty && !isAddingNew {
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Color(hex: 0x0058bc))
                    Text("タグがありません")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x181c23))
                    Text("タグを作るとタスクを分類しやすくなります。")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0x717786))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(tags) { tag in
                            tagRow(tag)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }

            if isAddingNew {
                newTagForm
            } else {
                Button {
                    isAddingNew = true
                    newTagName = ""
                    newTagColorIndex = 5
                } label: {
                    Label("新規タグ", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(hex: 0x0058bc))
                .padding(.vertical, 12)
            }
        }
        .frame(width: 400, height: 480)
        .background(Color(hex: 0xf7f8fb))
        .alert("タグを削除", isPresented: Binding(
            get: { tagToDelete != nil },
            set: { if !$0 { tagToDelete = nil } }
        )) {
            Button("キャンセル", role: .cancel) { tagToDelete = nil }
            Button("削除", role: .destructive) {
                if let tag = tagToDelete {
                    store.deleteTag(tag)
                    tagToDelete = nil
                }
            }
        } message: {
            if let tag = tagToDelete {
                Text("タグ「\(tag.name)」を削除します。タスクからタグが外れますが、タスクは削除されません。")
            }
        }
        .sheet(item: $editingTag) { tag in
            editTagSheet(tag)
        }
    }

    // MARK: - Tag row

    private func tagRow(_ tag: Tag) -> some View {
        HStack(spacing: 12) {
            tagChip(tag)
            Text("\(tag.items.count)件")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: 0x717786))
            Spacer()
            Button { editingTag = tag; editName = tag.name; editColorIndex = tag.colorIndex } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(hex: 0x717786))
            Button { tagToDelete = tag } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(hex: 0xc64f00))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xecedf3), lineWidth: 1))
    }

    // MARK: - New tag form

    private var newTagForm: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("タグ名", text: $newTagName)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .padding(8)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xecedf3), lineWidth: 1))
            }
            colorGrid(selection: $newTagColorIndex)
            HStack {
                Button("キャンセル") {
                    isAddingNew = false
                }
                .buttonStyle(.bordered)
                Button("追加") {
                    let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    store.addTag(name: trimmed, colorIndex: newTagColorIndex)
                    isAddingNew = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(12)
        .background(Color.white)
    }

    // MARK: - Edit tag sheet

    private func editTagSheet(_ tag: Tag) -> some View {
        VStack(spacing: 16) {
            Text("タグを編集")
                .font(.system(size: 15, weight: .semibold))
            TextField("タグ名", text: $editName)
                .textFieldStyle(.roundedBorder)
            colorGrid(selection: $editColorIndex)
            HStack {
                Spacer()
                Button("キャンセル") { editingTag = nil }
                    .buttonStyle(.bordered)
                Button("保存") {
                    let trimmed = editName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    store.updateTag(tag, name: trimmed, colorIndex: editColorIndex)
                    editingTag = nil
                }
                .buttonStyle(.borderedProminent)
                .disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(Color(hex: 0xf7f8fb))
    }

    // MARK: - Color grid

    private func colorGrid(selection: Binding<Int>) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 8), count: 6), spacing: 8) {
            ForEach(TagColor.allCases, id: \.rawValue) { color in
                Circle()
                    .fill(color.foregroundColor)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: color.foregroundColor.opacity(0.25), radius: 3, y: 1)
                    .overlay {
                        if selection.wrappedValue == color.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        selection.wrappedValue = color.rawValue
                    }
            }
        }
    }

    private func tagChip(_ tag: Tag) -> some View {
        let color = TagColor.from(index: tag.colorIndex)
        return Text(tag.name)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(color.foregroundColor)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.backgroundColor, in: Capsule())
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

